//
//  Controls.swift
//  HexaControl
//
//  Created by Yong Ee on 31/7/21.
//

import Foundation
import GameController

var DpadL = false
var DpadR = false
var DpadU = false
var DpadD = false
var xSpeed:Float = 0.0
var ySpeed:Float = 0.0

var timerL = CACurrentMediaTime()
var timerR = CACurrentMediaTime()

var oldTransSpeed: Float = 0.0
var oldRotSpeed: Float = 0.0

var RTpress = false
var LTpress = false

struct roboState{
    var gait: String = "Original"
    var lift: Int = 0
    var stepLength: Float = 1.0
    var marching: Bool = false
}


func JsonDumps(data: Dictionary<String,Any>) -> String{
    let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [])
    return String(data: jsonData!, encoding: .utf8) ?? "{\"Error\":\"Error\"}"
}

func CalcSpeed(x: Float, y: Float) -> Float{
    var speedR = (x*x + y*y).squareRoot()
    speedR = speedR * 1.2
    if speedR < 0.1{
        return 0.0
    }
    else {
        return min(speedR, 1.199)
    }
}

func CalcDir(x: Float, y: Float) -> Float{
    var atAng = Double(atan2(x,y)) * 180 / Double.pi
    if atAng < 0 {
        atAng +=  360
    }
    if atAng >= 359 {
        atAng = 0
    }
    return Float(atAng)
}

func IsAnalog(binding: String) -> Bool{
    return binding == "WCl" || binding == "WCr" || binding == "WCf" || binding == "WCb" || binding == "RCl" || binding == "RCr"
}

func ProcessInput(inpDat: String, gp: GCExtendedGamepad, bindings: Dictionary<String, String>, oldRState: roboState) -> (Dictionary<String,Any>, roboState){
    var rState = oldRState
    
    if inpDat == "Left Thumbstick"{
        var returnDict: Dictionary<String, Any> = [:]
        //discrete values
        if !IsAnalog(binding: bindings["LThumbL"]!){
            if gp.leftThumbstick.xAxis.value < -0.2 {
                let resDict = handleBoolVal(action: "LThumbL", value: true)
                returnDict.merge(resDict, uniquingKeysWith: { (first, _) in first })
            }
        }
        if !IsAnalog(binding: bindings["LThumbR"]!){
            if gp.leftThumbstick.xAxis.value > 0.2 {
                let resDict = handleBoolVal(action: "LThumbR", value: true)
                returnDict.merge(resDict, uniquingKeysWith: { (first, _) in first })
            }
        }
        if !IsAnalog(binding: bindings["LThumbU"]!){
            if gp.leftThumbstick.yAxis.value > 0.2 {
                let resDict = handleBoolVal(action: "LThumbU", value: true)
                returnDict.merge(resDict, uniquingKeysWith: { (first, _) in first })
            }
        }
        if !IsAnalog(binding: bindings["LThumbD"]!){
            if gp.leftThumbstick.yAxis.value < -0.2 {
                let resDict = handleBoolVal(action: "LThumbD", value: true)
                returnDict.merge(resDict, uniquingKeysWith: { (first, _) in first })
            }
        }
        if !IsAnalog(binding: bindings["LThumbL"]!) {
        returnDict.merge(handleBoolVal(action: "LThumbL", value: false), uniquingKeysWith: { (first, _) in first })
        }
        if !IsAnalog(binding: bindings["LThumbR"]!) {
        returnDict.merge(handleBoolVal(action: "LThumbR", value: false), uniquingKeysWith: { (first, _) in first })
        }
        if !IsAnalog(binding: bindings["LThumbU"]!) {
        returnDict.merge(handleBoolVal(action: "LThumbU", value: false), uniquingKeysWith: { (first, _) in first })
        }
        if !IsAnalog(binding: bindings["LThumbD"]!) {
        returnDict.merge(handleBoolVal(action: "LThumbD", value: false), uniquingKeysWith: { (first, _) in first })
        }
        print(returnDict)
        
        if (IsAnalog(binding: bindings["LThumbL"]!) || IsAnalog(binding: bindings["LThumbL"]!) || IsAnalog(binding: bindings["LThumbR"]!) || IsAnalog(binding: bindings["LThumbU"]!)){
            //continuous values
            //continuous walk
            if (bindings["LThumbL"] == "WCl" || bindings["LThumbR"] == "WCr") {
                xSpeed = gp.leftThumbstick.xAxis.value
            }
            else if (bindings["LThumbL"] == "WCr" || bindings["LThumbL"] == "WCl"){
                xSpeed = -gp.leftThumbstick.xAxis.value
            }
            if (bindings["LThumbU"] == "WCl" || bindings["LThumbD"] == "WCr"){
                xSpeed = gp.leftThumbstick.yAxis.value
            }
            else if (bindings["LThumbU"] == "WCr" || bindings["LThumbD"] == "WCl"){
                xSpeed = -gp.leftThumbstick.yAxis.value
            }
            if (bindings["LThumbL"] == "WClb" || bindings["LThumbR"] == "WCf") {
                ySpeed = gp.leftThumbstick.xAxis.value
            }
            else if (bindings["LThumbL"] == "WCf" || bindings["LThumbL"] == "WCb"){
                ySpeed = -gp.leftThumbstick.xAxis.value
            }
            if (bindings["LThumbU"] == "WCf" || bindings["LThumbD"] == "WCb"){
                ySpeed = gp.leftThumbstick.yAxis.value
            }
            else if (bindings["LThumbU"] == "WCb" || bindings["LThumbD"] == "WCf"){
                ySpeed = -gp.leftThumbstick.yAxis.value
            }
            
            var dir = 1
            var speed:Float = 0
            //continuous rotation
            if (bindings["LThumbL"] == "RCl" || bindings["LThumbR"] == "RCr"){
                if gp.leftThumbstick.xAxis.value < 0{
                    dir = -1
                }
                speed = abs(gp.leftThumbstick.xAxis.value*10.0)
                if speed < 0.1{
                    speed = 0
                }
            }
            else if (bindings["LThumbL"] == "RCr" || bindings["LThumbR"] == "RCl"){
                dir = -1
                if gp.leftThumbstick.xAxis.value < 0{
                    dir = 1
                }
                speed = abs(gp.leftThumbstick.xAxis.value*10.0)
                if speed < 0.1{
                    speed = 0
                }
            }
            
            let transSpeed = CalcSpeed(x: xSpeed, y: ySpeed)
            returnDict.merge(["RC": ["dir":dir,"sp":speed],"WC": ["dir":CalcDir(x: xSpeed, y: ySpeed), "sp":transSpeed]], uniquingKeysWith: { (first, _) in first })
            
            
        }
        return (["LStick": returnDict], rState)
    }
    else if inpDat == "Right Thumbstick"{
        var returnDict: Dictionary<String, Any> = [:]
        //discrete values
        if !IsAnalog(binding: bindings["RThumbL"]!){
            if gp.rightThumbstick.xAxis.value < -0.2 {
                let resDict = handleBoolVal(action: "RThumbL", value: true)
                returnDict.merge(resDict, uniquingKeysWith: { (first, _) in first })
            }
        }
        if !IsAnalog(binding: bindings["RThumbR"]!){
            if gp.rightThumbstick.xAxis.value > 0.2 {
                let resDict = handleBoolVal(action: "RThumbR", value: true)
                returnDict.merge(resDict, uniquingKeysWith: { (first, _) in first })
            }
        }
        if !IsAnalog(binding: bindings["RThumbU"]!){
            if gp.rightThumbstick.yAxis.value > 0.2 {
                let resDict = handleBoolVal(action: "RThumbU", value: true)
                returnDict.merge(resDict, uniquingKeysWith: { (first, _) in first })
            }
        }
        if !IsAnalog(binding: bindings["RThumbD"]!){
            if gp.rightThumbstick.yAxis.value < -0.2 {
                let resDict = handleBoolVal(action: "RThumbD", value: true)
                returnDict.merge(resDict, uniquingKeysWith: { (first, _) in first })
            }
        }
        if !IsAnalog(binding: bindings["RThumbL"]!) {
            returnDict.merge(handleBoolVal(action: "RThumbL", value: false), uniquingKeysWith: { (first, _) in first })
        }
        if !IsAnalog(binding: bindings["RThumbR"]!) {
            returnDict.merge(handleBoolVal(action: "RThumbR", value: false), uniquingKeysWith: { (first, _) in first })
        }
        if !IsAnalog(binding: bindings["RThumbU"]!) {
            returnDict.merge(handleBoolVal(action: "RThumbU", value: false), uniquingKeysWith: { (first, _) in first })
        }
        if !IsAnalog(binding: bindings["RThumbD"]!) {
            returnDict.merge(handleBoolVal(action: "RThumbD", value: false), uniquingKeysWith: { (first, _) in first })
        }
        
        if (IsAnalog(binding: bindings["RThumbD"]!) || IsAnalog(binding: bindings["RThumbL"]!) || IsAnalog(binding: bindings["RThumbR"]!) || IsAnalog(binding: bindings["RThumbU"]!)){
            //continuous values
            //continuous walk
            if (bindings["RThumbL"] == "WCl" || bindings["RThumbR"] == "WCr") {
                xSpeed = gp.rightThumbstick.xAxis.value
            }
            else if (bindings["RThumbL"] == "WCr" || bindings["RThumbL"] == "WCl"){
                xSpeed = -gp.rightThumbstick.xAxis.value
            }
            if (bindings["RThumbU"] == "WCl" || bindings["RThumbD"] == "WCr"){
                xSpeed = gp.rightThumbstick.yAxis.value
            }
            else if (bindings["RThumbU"] == "WCr" || bindings["RThumbD"] == "WCl"){
                xSpeed = -gp.rightThumbstick.yAxis.value
            }
            if (bindings["RThumbL"] == "WClb" || bindings["RThumbR"] == "WCf") {
                ySpeed = gp.rightThumbstick.xAxis.value
            }
            else if (bindings["RThumbL"] == "WCf" || bindings["RThumbL"] == "WCb"){
                ySpeed = -gp.rightThumbstick.xAxis.value
            }
            if (bindings["RThumbU"] == "WCf" || bindings["RThumbD"] == "WCb"){
                ySpeed = gp.rightThumbstick.yAxis.value
            }
            else if (bindings["RThumbU"] == "WCb" || bindings["RThumbD"] == "WCf"){
                ySpeed = -gp.rightThumbstick.yAxis.value
            }
            
            var dir = 1
            var speed:Float = 0
            //continuous rotation
            if (bindings["RThumbL"] == "RCl" || bindings["RThumbR"] == "RCr"){
                if gp.rightThumbstick.xAxis.value < 0{
                    dir = -1
                }
                speed = abs(gp.rightThumbstick.xAxis.value*10.0)
                if speed < 0.1{
                    speed = 0
                }
            }
            else if (bindings["RThumbL"] == "RCr" || bindings["RThumbR"] == "RCl"){
                dir = -1
                if gp.rightThumbstick.xAxis.value < 0{
                    dir = 1
                }
                speed = abs(gp.rightThumbstick.xAxis.value*10.0)
                if speed < 0.1{
                    speed = 0
                }
            }
            if speed == 0 {
                returnDict.merge(["RC": ["dir":dir,"sp":speed]], uniquingKeysWith: { (first, _) in first })
            } else {
                let nowTime = CACurrentMediaTime()
                if nowTime - timerR > 0.5 {
                    timerR = nowTime
                    speed = speed/Float(10).rounded()*10
                    if speed != oldRotSpeed{
                        returnDict.merge(["RC": ["dir":dir,"sp":speed]], uniquingKeysWith: { (first, _) in first })
                        oldRotSpeed = speed
                    }
                }
            }
            
            let transSpeed = CalcSpeed(x: xSpeed, y: ySpeed)
            returnDict.merge(["RC": ["dir":dir,"sp":speed],"WC": ["dir":CalcDir(x: xSpeed, y: ySpeed), "sp":transSpeed]], uniquingKeysWith: { (first, _) in first })
                        
        }
        return (["RStick": returnDict], rState)
    }
    
    var action = ""
    var value = false
    
    switch inpDat {
    case "Left Trigger":
        action = "L2"
        value = gp.leftTrigger.isPressed
        if value == LTpress {
            return (["None":"None"], rState)
        } else {
            LTpress = value
        }
    case "Right Trigger":
        action = "R2"
        value = gp.rightTrigger.isPressed
        if value == RTpress {
            return (["None":"None"], rState)
        } else {
            RTpress = value
        }
    case "Left Shoulder":
        action = "L1"
        value = gp.leftShoulder.isPressed
    case "Right Shoulder":
        action = "R1"
        value = gp.rightShoulder.isPressed
    case "Direction Pad":
        if DpadL != gp.dpad.left.isPressed {
            action = "DpadL"
            DpadL = gp.dpad.left.isPressed
            value = DpadL
        } else if DpadR != gp.dpad.right.isPressed{
            action = "DpadR"
            DpadR = gp.dpad.right.isPressed
            value = DpadR
        } else if DpadU != gp.dpad.up.isPressed{
            action = "DpadU"
            DpadU = gp.dpad.up.isPressed
            value = DpadU
        } else if DpadD != gp.dpad.down.isPressed{
            action = "DpadD"
            DpadD = gp.dpad.down.isPressed
            value = DpadD
        }
    case "Button A":
        action = "ButtA"
        value = gp.buttonA.isPressed
    case "Button B":
        action = "ButtB"
        value = gp.buttonB.isPressed
    case "Button X":
        action = "ButtX"
        value = gp.buttonX.isPressed
    case "Button Y":
        action = "ButtY"
        value = gp.buttonY.isPressed
    case "Button Menu":
        action = "Menu"
        value = gp.buttonMenu.isPressed
    case "Button Home":
        action = "Home"
        value = gp.buttonHome?.isPressed ?? false
    case "Left Thumbstick Button":
        action = "LThumbB"
        value = gp.leftThumbstickButton?.isPressed ?? false
    case "Right Thumbstick Button":
        action = "RThumbB"
        value = gp.leftThumbstickButton?.isPressed ?? false
    default:
        action = "None"
    }
    
    
    
    func handleBoolVal(action: String, value: Bool) -> Dictionary<String,Any>{
        if value == false {
            if bindings[action] == "SPl" || bindings[action] == "SPr" {
                return ["SP":["dir":-1]]
            }
            if bindings[action] == "PIu" || bindings[action] == "PId" {
                return ["PI":["dir":0]]
            }
            return ["None":"None"]
        }
        
        switch bindings[action]{
        case "PIu":
            if value == true {
                return ["PI":["dir":1]]
            }
        case "PId":
            if value == true {
                return ["PI":["dir":-1]]
            }
        case "SLu":
            if value == true {
                rState.stepLength += 0.05
                if rState.stepLength > 1{
                    rState.stepLength = 1.0
                }
                return ["SL":["num":rState.stepLength]]
            }
        case "SLd":
            if value == true {
                rState.stepLength -= 0.05
                if rState.stepLength <= 0 {
                    rState.stepLength = 0.05
                }
                return ["SL":["num":rState.stepLength]]
            }
        case "LIu":
            if value == true {
                rState.lift += 5
                if rState.lift > 50{
                    rState.lift = 50
                }
                return ["LI":["num":rState.lift]]
            }
        case "LId":
            if value == true {
                rState.lift -= 5
                if rState.lift < -20{
                    rState.lift = -20
                }
                return ["LI":["num":rState.lift]]
            }
        case "SPl":
            if value == true {
                return ["SP":["dir":0]]
            }
        case "SPr":
            if value == true {
                return ["SP":["dir":1]]
            }
        case "PGA":
            if value == true {
                if rState.gait == "Original"{
                    rState.gait = "Tripod"
                } else if rState.gait == "Tripod"{
                    rState.gait = "Amble"
                } else if rState.gait == "Amble"{
                    rState.gait = "Ripple"
                } else if rState.gait == "Ripple"{
                    rState.gait = "Original"
                }
                return ["GA":["dat":rState.gait]]
            }
        case "NGA":
            if value == true {
                if rState.gait == "Original"{
                    rState.gait = "Ripple"
                } else if rState.gait == "Ripple"{
                    rState.gait = "Amble"
                } else if rState.gait == "Amble"{
                    rState.gait = "Tripod"
                } else if rState.gait == "Tripod"{
                    rState.gait = "Original"
                }
                return ["GA":["dat":rState.gait]]
            }
        case "GAr":
            if value == true{
                rState.gait = "Ripple"
                return ["GA":["dat":rState.gait]]
            }
        case "GAo":
            if value == true{
                rState.gait = "Original"
                return ["GA":["dat":rState.gait]]
            }
        case "GAa":
            if value == true{
                rState.gait = "Amble"
                return ["GA":["dat":rState.gait]]
            }
        case "GAt":
            if value == true{
                rState.gait = "Tripod"
                return ["GA":["dat":rState.gait]]
            }
        case "MA":
            if value == true{
                rState.marching = !rState.marching
                return ["MA":["dat":rState.marching]]
            }
        case "RE":
            if value == true{
                return ["RE":["dat":1]]
            }
        default:
            return ["None":"None"]
        }
        
        return ["None":"None"]
    }
    
    return (handleBoolVal(action: action, value: value), rState)
}

