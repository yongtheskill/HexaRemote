//
//  HexaControlApp.swift
//  HexaControl
//
//  Created by Yong Ee on 31/7/21.
//

import SwiftUI

@main
struct HexaControlApp: App {
    @State private var isLink = false
    @State private var hexaLink = ""
    
    
    var body: some Scene {
        WindowGroup {
            if isLink {
                NavigationView{
                    ConnectedView(hexaLink: $hexaLink)
                }.navigationViewStyle(StackNavigationViewStyle())
                .onOpenURL(perform: { url in
                    print("opened")
                    isLink = true
                    hexaLink = String(url.absoluteString.dropFirst(20)).removingPercentEncoding!
                })
                
            } else {
                HomeView()
                    .onOpenURL(perform: { url in
                        print("opened")
                        isLink = true
                        hexaLink = String(url.absoluteString.dropFirst(20)).removingPercentEncoding!
                    })
            }
        }
    }
}
