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
    @State var search: String = ""

    var body: some View {
        TabView {
            NavigationView {
                TrackList(selectedInstance: $selectedInstance, token: $token)
                    .navigationBarTitle("Audios", displayMode: .inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Menu(selectedInstance?.nick ?? "Select a Bot") {
                                Picker("Bots", selection: $selectedInstance) {
                                    ForEach(instances, id: \.self) {
                                        Text($0.nick).tag(Optional($0))
                                    }
                                }
                            }
                        }
                    }
                    .navigationBarItems(trailing: Button(action: {
                        Task {
                            await stopPlayback(instanceId: selectedInstance!.uuid)
                        }
                    }) {
                        Label("", systemImage: "stop.fill")
                    })
            }
            .navigationViewStyle(.stack)
            .tabItem {
                VStack {
                    Image(systemName: "play.fill")
                    Text("Audios")
                }
            }

            NavigationView {
                ConnectTo(selectedInstance: $selectedInstance)
                    .navigationBarTitle("Change Channel", displayMode: .inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Menu(selectedInstance?.nick ?? "Select a Bot") {
                                Picker("Bots", selection: $selectedInstance) {
                                    ForEach(instances, id: \.self) {
                                        Text($0.nick).tag(Optional($0))
                                    }
                                }
                            }
                        }
                    }
                    .navigationBarItems(trailing: Button(action: {
                        Task {
                            await stopPlayback(instanceId: selectedInstance!.uuid)
                        }
                    }) {
                        Label("", systemImage: "stop.fill")
                    })
            }
            .navigationViewStyle(.stack)
            .tabItem {
                VStack {
                    Image(systemName: "cable.connector")
                    Text("Change Channel")
                }
            }
            
            NavigationView {
                DebugView()
                    .navigationBarTitle("Change Channel", displayMode: .inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Menu(selectedInstance?.nick ?? "Select a Bot") {
                                Picker("Bots", selection: $selectedInstance) {
                                    ForEach(instances, id: \.self) {
                                        Text($0.nick).tag(Optional($0))
                                    }
                                }
                            }
                        }
                    }
                    .navigationBarItems(trailing: Button(action: {
                        Task {
                            await stopPlayback(instanceId: selectedInstance!.uuid)
                        }
                    }) {
                        Label("", systemImage: "stop.fill")
                    })
            }
            .navigationViewStyle(.stack)
            .tabItem {
                VStack {
                    Image(systemName: "gear.circle")
                    Text("Debug")
                }
            }
        }
        .onAppear {
            Task {
                await initView()
            }
        }
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
