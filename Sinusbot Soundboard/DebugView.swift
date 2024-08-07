//
//  DebugView.swift
//  Sinusbot Soundboard
//
//  Created by Bernardo Ruiz  on 15/12/22.
//

import SwiftUI

struct DebugView: View {
    @State var savedToken = UserDefaults.standard.string(forKey: "token") ?? "No token"
    var body: some View {
        VStack {
            Text("Auth")
            Button(action: printToken) {
                Text("Print Token")
            }
            Button(action: {
                UserDefaults.standard.set("bad Token", forKey: "token")
            }) {
                Text("Set and Print bad token")
            }
            Text("Saved token: \(savedToken)")
            Divider()
            Text("Actions")
            Button(action: {
                Task {
                    printToken()
                    UserDefaults.standard.set("test", forKey: "token")
                    printToken()
                    await login()
                }
            }) {
                Text("Login and print")
            }
            Button(action: {
                Task {
                    if let tracks = await getTracks() {
                        print(tracks)
                    } else {
                        print("No tracks received")
                    }
                }
            }) {
                Text("Get Tracks and print")
            }
            Button(action: {
                UserDefaults.standard.set(false, forKey: "isOnboarded")
            }) {
                Text("Reset Onboard")
            }
        }
    }

    func printToken() {
        print(UserDefaults.standard.string(forKey: "token") ?? "No token")
    }
}

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView()
    }
}
