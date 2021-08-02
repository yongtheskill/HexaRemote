//
//  JavascriptRun.swift
//  JavascriptRun
//
//  Created by Yong Ee on 1/8/21.
//

import Foundation

import JavaScriptCore

let jsContext = JSContext()!

func initJs(initData: String){
    jsContext.exceptionHandler = { context, exception in
        print(exception!.toString()!)
    }
    
    if let filepath = Bundle.main.path(forResource: "mind-framework", ofType: "js") {
        do {
            let contents = try String(contentsOfFile: filepath)
            let finalJs = initData + contents
            
            jsContext.evaluateScript(finalJs)
            
        } catch {
            print("contents cant be loaded")
        }
    } else {
        print("file not found")
    }
    
    
    let jsData = """
    mind.init({
        callback: function(robot){
            skillID = "bebc774f"
            robot.connectSkill({
                skillID: skillID
            });
        }
    });
    """
    jsContext.evaluateScript(jsData)

}


func sendData(jsonData: String){
    let jsData = """
    robot.sendData({
        skillID: skillID,
        data: '\(jsonData)'
    })
    """
    print(jsData)
    jsContext.evaluateScript(jsData)
}
