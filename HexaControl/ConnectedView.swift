//
//  ConnectedView.swift
//  HexaControl
//
//  Created by Yong Ee on 31/7/21.
//


//self.viewModel.valuePublisher.send(self.message)


import SwiftUI
import GameController

struct ControlGroup: Identifiable {
    let name: String
    let elements: [ControlElement]
    let id = UUID()
}

struct ControlElement: Identifiable, Hashable{
    let name: String
    let cName: String
    let id = UUID()
}
var timer: Timer?

var cachedMovementL: Dictionary<String,Any> = [:]
var cachedMovementR: Dictionary<String,Any> = [:]

struct ConnectedView: View {
    @Binding public var hexaLink : String
    
    @ObservedObject public var viewModel = ViewModel()
    
    @State var rState = roboState()
    
    @State var bindings = ["RThumbL":"WCl",
                           "RThumbR":"WCr",
                           "RThumbU":"WCf",
                           "RThumbD":"WCb",
                           "LThumbL":"RCl",
                           "LThumbR":"RCr",
                           "LThumbU":"PIu",
                           "LThumbD":"PId",
                           "DpadL":"SLd",
                           "DpadR":"SLu",
                           "DpadU":"LIu",
                           "DpadD":"LId",
                           "L2":"SPl",
                           "R2":"SPr",
                           "L1":"PGA",
                           "R1":"NGA",
                           "ButtA":"GAr",
                           "ButtB":"GAo",
                           "ButtX":"GAa",
                           "ButtY":"GAt",
                           "Menu":"MA",
                           "Home":"RE",
                           "LThumbB":"None",
                           "RThumbB":"None"]
    @State var cNameBindings = ["WCl": "Walk Left",
                                "WCr": "Walk Right",
                                "WCf": "Walk Forwards",
                                "WCb": "Walk Backwards",
                                "RCl": "Rotate Head Left",
                                "RCr": "Rotate Head Right",
                                "PIu": "Pitch Up",
                                "PId": "Pitch Down",
                                "SLd": "Increase Stride Length",
                                "SLu": "Decrease Stride Length",
                                "LIu": "Increase Height",
                                "LId": "Decrease Height",
                                "SPl": "Rotate Robot Left",
                                "SPr": "Rotate Robot Right",
                                "PGA": "Previous Gait",
                                "NGA": "Next Gait",
                                "GAr": "Set Gait: Ripple",
                                "GAo": "Set Gait: Original",
                                "GAa": "Set Gait: Amble",
                                "GAt": "Set Gait: Tripod",
                                "MA": "Toggle March Mode",
                                "RE": "Relax Robot",
                                "None": "None",
                                ]

    
    @State var isSearching = false
    @State var conName = ""
    @State var debugData = ""
    
    @State var selected = 0
    @State var menuOpen = false
    
    @State var initted = false
    
    
    var controlGroups = [
        ControlGroup(name: "Right Thumbstick",
                     elements: [
                        ControlElement(name: "Right Thumbstick (Left)", cName: "RThumbL"),
                        ControlElement(name: "Right Thumbstick (Right)", cName: "RThumbR"),
                        ControlElement(name: "Right Thumbstick (Up)", cName: "RThumbU"),
                        ControlElement(name: "Right Thumbstick (Down)", cName: "RThumbD"),
                        ControlElement(name: "Right Thumbstick Button", cName: "RThumbB")
                     ]),
        ControlGroup(name: "Left Thumbstick",
                     elements: [
                        ControlElement(name: "Left Thumbstick (Left)", cName: "LThumbL"),
                        ControlElement(name: "Left Thumbstick (Right)", cName: "LThumbR"),
                        ControlElement(name: "Left Thumbstick (Up)", cName: "LThumbU"),
                        ControlElement(name: "Left Thumbstick (Down)", cName: "LThumbD"),
                        ControlElement(name: "Left Thumbstick Button", cName: "LThumbB")
                     ]),
        ControlGroup(name: "Direction Pad",
                     elements: [
                        ControlElement(name: "Direction Pad (Left)", cName: "DpadL"),
                        ControlElement(name: "Direction Pad (Right)", cName: "DpadR"),
                        ControlElement(name: "Direction Pad (Up)", cName: "DpadU"),
                        ControlElement(name: "Direction Pad (Down)", cName: "DpadD")
                     ]),
        ControlGroup(name: "Shoulder Buttons",
                     elements: [
                        ControlElement(name: "Left Trigger", cName: "L2"),
                        ControlElement(name: "Right Trigger", cName: "R2"),
                        ControlElement(name: "Left Shoulder Button", cName: "L1"),
                        ControlElement(name: "Right Shoulder Button", cName: "R1")
                     ]),
        ControlGroup(name: "Right Hand Buttons",
                     elements: [
                        ControlElement(name: "A / Cross", cName: "ButtA"),
                        ControlElement(name: "B / Circle", cName: "ButtB"),
                        ControlElement(name: "X / Square", cName: "ButtX"),
                        ControlElement(name: "Y / Triangle", cName: "ButtY"),
                     ]),
        ControlGroup(name: "Miscellaneous Buttons",
                     elements: [
                        ControlElement(name: "Menu", cName: "Menu"),
                        ControlElement(name: "Home", cName: "Home")
                     ])
    ]
    
    
    var body: some View {
        ZStack{
            if !menuOpen{
                ZStack{
                    WebView(url: .localUrl, addr: "", viewModel: viewModel)
                    .onReceive(self.viewModel.showLoader.receive(on: RunLoop.main)) { value in
                        if value == false{
                            self.viewModel.valuePublisher.send(hexaLink + """
        mind.init({
            callback: function(robot) {
                skillID = "bebc774f"
                robot.connectSkill({
                    skillID: skillID
                });
                window.conJsonRcv = (data) => {
                    robot.sendData({
                        skillID: skillID,
                        data: data
                    })
                }
            }
        });
    """)
                        }
                    }
                    .onChange(of: hexaLink){ value in
                        self.viewModel.valuePublisher.send(value + """
    mind.init({
        callback: function(robot) {
            skillID = "bebc774f"
            robot.connectSkill({
                skillID: skillID
            });
            window.conJsonRcv = (data) => {
                robot.sendData({
                    skillID: skillID,
                    data: data
                })
            }
        }
    });
""")
                    }
                    
                    
                    VStack{
                        if isSearching{
                            ProgressView("Waiting for controller to be connected.")
                            Text("Please use bluetooth or directly connect a controller.")
                                .padding()
                        } else {
                            VStack {
                                Text("Connected to \(conName)")
                                    .font(.title2)
                                    .padding()
                                
                                HStack{
                                    Text("Gait: \(rState.gait)")
                                        .font(.title2)
                                        .padding()
                                    Text("Lift: \(rState.lift)")
                                        .font(.title2)
                                        .padding()
                                }
                                HStack{
                                    Text("Step length: \(rState.stepLength, specifier: "%.2f")")
                                        .font(.title2)
                                        .padding()
                                    if rState.marching {
                                        Text("Marching: True")
                                            .font(.title2)
                                            .padding()
                                    } else {
                                        Text("Marching: False")
                                            .font(.title2)
                                            .padding()
                                    }
                                }
                                Button(action: {
                                    menuOpen = true
                                }) {
                                    Text("Setup Controller")
                                        .font(.title)
                                        .foregroundColor(Color.white)
                                }.padding(.all)
                                    .background(Color.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                                
                            }
                        }
                    }
                    .onAppear(perform: {
                        ConnectController()
                    })
                }
                .navigationBarHidden(true)
            }
            else {
                List{
                    ForEach(controlGroups){ cGroup in
                        Section(header: Text("\(cGroup.name)")){
                            ForEach(cGroup.elements) { elem in
                                HStack{
                                    Text(elem.name)
                                    Spacer()
                                    Menu {
                                        Menu("Walk") {
                                            Button("Walk Backwards", action: { bindings[elem.cName] = "WCb" })
                                            Button("Walk Forward", action: { bindings[elem.cName] = "WCf" })
                                            Button("Walk Right", action: { bindings[elem.cName] = "WCr" })
                                            Button("Walk Left", action: { bindings[elem.cName] = "WCl" })
                                        }
                                        Menu("Pitch/Rotate") {
                                            Button("Rotate Head Right", action: { bindings[elem.cName] = "RCr" })
                                            Button("Rotate Body Left", action: { bindings[elem.cName] = "SPl" })
                                            Button("Rotate Body Right", action: { bindings[elem.cName] = "SPr" })
                                            Button("Rotate Head Left", action: { bindings[elem.cName] = "RCl" })
                                            Button("Pitch Down", action: { bindings[elem.cName] = "PId" })
                                            Button("Pitch Up", action: { bindings[elem.cName] = "PIu" })
                                            
                                        }
                                        Menu("Gait") {
                                            Button("Toggle March Mode", action: { bindings[elem.cName] = "MA" })
                                            Button("Set Gait: Original", action: { bindings[elem.cName] = "GAo" })
                                            Button("Set Gait: Amble", action: { bindings[elem.cName] = "GAa" })
                                            Button("Set Gait: Tripod", action: { bindings[elem.cName] = "GAt" })
                                            Button("Set Gait: Ripple", action: { bindings[elem.cName] = "GAr" })
                                            Button("Next Gait", action: { bindings[elem.cName] = "NGA" })
                                            Button("Previous Gait", action: { bindings[elem.cName] = "PGA" })
                                        }
                                        Menu("Movement") {
                                            Button("Decrease Stride Length", action: { bindings[elem.cName] = "SLd" })
                                            Button("Increase Stride Length", action: { bindings[elem.cName] = "SLu" })
                                            Button("Decrease Height", action: { bindings[elem.cName] = "LId" })
                                            Button("Increase Height", action: { bindings[elem.cName] = "LIu" })
                                            
                                        }
                                        Menu("Utility") {
                                            Button("Relax", action: { bindings[elem.cName] = "RE" })
                                            Button("None", action: { bindings[elem.cName] = "None" })
                                        }
                                    } label: {
                                        Text(cNameBindings[bindings[elem.cName]!]!)
                                        Image(systemName: "chevron.right")
                                            .font(.body)
                                    }
                                    
                                }
                            }
                        }
                    }
                }.listStyle(InsetGroupedListStyle())
                    .navigationTitle("Change controller bindings")
                    .toolbar {
                        Button("Done") {
                            menuOpen = false
                        }
                    }
            }
        }
        
    }
    
    
    
    
    
    
    
    
    
    
    func ConnectController(){
        
        
        isSearching = true
        
        let nCon = GCController.controllers().count
        if (nCon > 0){
            let gController = GCController.controllers()[0]
            gController.extendedGamepad!.valueChangedHandler = inpChanged
            isSearching = false
            conName = gController.vendorName ?? ""
            timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                sendHeartbeat()
            }
            NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidDisconnect, object: nil, queue: nil, using: conDisconnected)
        } else {
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidConnect, object: nil, queue: nil, using: conConnected)
            NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidDisconnect, object: nil, queue: nil, using: conDisconnected)
        }
        
        func conDisconnected(notif: Notification) -> Void{
            print("dc")
            ConnectController()
            isSearching = true
        }
        
        func conConnected(notif: Notification) -> Void{
            let gController = notif.object as? GCController
            gController?.extendedGamepad!.valueChangedHandler = inpChanged
            isSearching = false
            conName = gController?.vendorName ?? ""
            timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                sendHeartbeat()
            }
        }
        
        func sendHeartbeat(){
            let mvmtL = cachedMovementL["LStick"]
            let mvmtR = cachedMovementR["RStick"]
            if mvmtL != nil && mvmtR == nil {
                let finalData = JsonDumps(data: mvmtL as! [String:Any])
                self.viewModel.valuePublisher.send("conJsonRcv('\(finalData)');")
            }
            if mvmtL == nil && mvmtR != nil {
                let finalData = JsonDumps(data: mvmtR as! [String:Any])
                self.viewModel.valuePublisher.send("conJsonRcv('\(finalData)');")
            }
            if mvmtL != nil && mvmtR != nil {
                var finalDict: Dictionary<String,Any> = [:]
                
                let dataR = mvmtR as! [String:Any]
                let dataL = mvmtL as! [String:Any]
                
                let rDatR = dataR["RC"] as! [String:Any]
                let rDatL = dataL["RC"] as! [String:Any]
                
                let tDatR = dataR["WC"] as! [String:Any]
                let tDatL = dataL["WC"] as! [String:Any]
                
                let rSpeedR = rDatR["sp"] as! Float
                
                let tSpeedR = tDatR["sp"] as! Float
                
                if rSpeedR != 0 {
                    finalDict["RC"] = rDatR
                } else {
                    finalDict["RC"] = rDatL
                }
                
                if tSpeedR != 0 {
                    finalDict["WC"] = tDatR
                } else {
                    finalDict["WC"] = tDatL
                }
                
                
                finalDict.merge(dataR, uniquingKeysWith: { (first, _) in first })
                finalDict.merge(dataL, uniquingKeysWith: { (first, _) in first })
                
                let finalData = JsonDumps(data: finalDict)
                self.viewModel.valuePublisher.send("conJsonRcv('\(finalData)');")
                
            }
        }
        
        func inpChanged(gp: GCExtendedGamepad, ele: GCControllerElement) -> Void {
            
            let inputData = ele.aliases.first ?? "none"
            var outputDat: Dictionary<String,Any>
            (outputDat,rState) = ProcessInput(inpDat: inputData, gp: gp, bindings: bindings, oldRState: rState)
            if let _ = outputDat["LStick"]{
                cachedMovementL = outputDat
                
            } else if let _ = outputDat["RStick"]{
                cachedMovementR = outputDat
                
            }else if let _ = outputDat["RE"]{
                cachedMovementL = [:]
                cachedMovementR = [:]
                let finalData = JsonDumps(data: outputDat)
                if finalData != "{\"None\":\"None\"}"{
                    self.viewModel.valuePublisher.send("conJsonRcv('\(finalData)');")
                }
            }
            else {
                let finalData = JsonDumps(data: outputDat)
                if finalData != "{\"None\":\"None\"}"{
                    self.viewModel.valuePublisher.send("conJsonRcv('\(finalData)');")
                    print(finalData)
                }
            }
        }
    }
    
}

struct ConnectedView_Previews: PreviewProvider {
    static var previews: some View {
        //ConnectedView()
        HomeView()
    }
}
