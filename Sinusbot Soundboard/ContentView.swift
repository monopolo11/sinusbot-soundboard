//
//  ContentView.swift
//  Sinusbot Soundboard
//
//  Created by Bernardo Ruiz  on 12/12/22.
//

import AlertToast
import SwiftUI

struct ContentView: View {
    @State private var token = UserDefaults.standard.string(forKey: "token")
    @State private var instances: [Instance] = []
    @State private var shouldBeOnboarded: Bool = !UserDefaults.standard.bool(forKey: "isOnboarded")
    @State var selectedInstance: Instance? = nil
    @State var search: String = ""
    @State private var showToast: Bool = false
    @State private var toastTitle: String = ""
    @State private var toastType: AlertToast.AlertType = .regular

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
                            await stopPlay()
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
                            await stopPlay()
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
                OnboardingContent()
                    .navigationBarTitle("Settings", displayMode: .inline)
            }
            .navigationViewStyle(.stack)
            .tabItem {
                VStack {
                    Image(systemName: "gear.circle")
                    Text("Settings")
                }
            }
        }
        .sheet(isPresented: $shouldBeOnboarded, onDismiss: { Task { await initView() }}) {
            OnboardingContent()
        }
        .interactiveDismissDisabled()
        .onChange(of: selectedInstance) { _ in
            toastType = .regular
            toastTitle = "Selected: \(selectedInstance?.nick ?? "N/A")"
            showToast.toggle()
        }
        .toast(isPresenting: $showToast) { AlertToast(displayMode: .banner(.pop), type: toastType, title: toastTitle) }
        .onAppear {
            Task {
                if !shouldBeOnboarded {
                    await initView()
                }
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

    func stopPlay() async {
        let success = await stopPlayback(instanceId: selectedInstance!.uuid)
        if success {
            toastType = .complete(.green)
            toastTitle = "Stoped play"
            showToast.toggle()
        } else {
            toastType = .error(.red)
            toastTitle = "Failed to stop, verify credentials"
            showToast.toggle()
        }
    }
}
