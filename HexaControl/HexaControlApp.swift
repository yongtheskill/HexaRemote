//
//  HexaControlApp.swift
//  HexaControl
//
//  Created by Yong Ee on 31/7/21.
//

import SwiftUI

@main
struct HexaControlApp: App {
    @State private var isLink = true
    @State private var hexaLink = ""
    
    
    var body: some Scene {
        WindowGroup {
            if isLink {
                NavigationView{
                ConnectedView(hexaLink: $hexaLink)
                    .onOpenURL(perform: { url in
                        isLink = true
                        hexaLink = String(url.absoluteString.dropFirst(20)).removingPercentEncoding!
                    })
                }.navigationViewStyle(StackNavigationViewStyle())

            } else {
                HomeView()
            }
        }
    }
}
