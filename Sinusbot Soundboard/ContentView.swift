//
//  ContentView.swift
//  Sinusbot Soundboard
//
//  Created by Bernardo Ruiz  on 12/12/22.
//

import CoreData
import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var token = UserDefaults.standard.string(forKey: "token")

    @State private var instances: [Instance] = []
    @State var selectedInstance: Instance? = nil
    
    

    var body: some View {
        NavigationView {
            TabView {
                if !instances.isEmpty {
                    TrackList(selectedInstance: $selectedInstance,token: $token).tabItem {
                        Label("Audios", systemImage: "play.fill")
                    }
                    ConnectTo(selectedInstance: $selectedInstance).tabItem {
                        Label("Connect", systemImage: "cable.connector")
                    }
                    DebugView().tabItem {
                        Label("Debug", systemImage: "gear.circle.fill")
                    }
                } else {
                        ProgressView()
                }
            }
            .onAppear {
                Task {
                    await initView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Picker("Bots", selection: $selectedInstance) {
                        ForEach(instances, id: \.self) {
                            Text($0.nick).tag(Optional($0))
                        }
                    }
                }
                ToolbarItem(placement: .navigation) {
                    Button(action: {
                        Task {
                            await stopPlayback(instanceId: selectedInstance!.uuid)
                        }
                    }) {
                        Label("s", systemImage: "stop.fill")
                    }
            }

            }
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
    }
    
     func initView() async {
        await getInfoAndValidateToken()
        if token == nil { await login() }
        if let instanceList = await getInstances() {
            selectedInstance = instanceList.first!
            instances = instanceList
        } else {
            print("Failed to get instances")
        }
    }
}
