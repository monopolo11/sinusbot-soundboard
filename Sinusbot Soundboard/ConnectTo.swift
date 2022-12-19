//
//  ConnectTo.swift
//  Sinusbot Soundboard
//
//  Created by Bernardo Ruiz  on 16/12/22.
//

import AlertToast
import SwiftUI

struct ConnectTo: View {
    @Binding var selectedInstance: Instance?
    @State var channels: [Channel] = []
    @State var selectedChannel: Channel?
    @State private var showToast: Bool = false
    @State private var toastTitle: String = ""
    @State private var toastType: AlertToast.AlertType = .regular

    var body: some View {
        VStack(alignment: .center) {
            Picker("Channels", selection: $selectedChannel) {
                Text("Select a Channel").tag(nil as Channel?)
                ForEach(channels, id: \.self) {
                    Text($0.name).tag($0 as Channel?)
                }
            }
            .buttonStyle(.bordered)
            .onChange(of: selectedInstance) { _ in
                Task {
                    await getAgain()
                }
            }
            Button(action: {
                Task {
                    let success = await changeChannel(instanceId: selectedInstance!.uuid, channelId: selectedChannel!.id)
                    if success {
                        toastTitle = "Changed Channel"
                        toastType = .complete(.green)
                        showToast.toggle()
                    }
                    try await Task.sleep(nanoseconds: UInt64(0.5 * Double(NSEC_PER_SEC)))
                    await getAgain()
                }
            }) {
                Text("Change")
            }.disabled(selectedChannel == nil)
            Text(selectedChannel?.clients?.isEmpty ?? true ? "No users connected" : "Connected users")
            if selectedChannel != nil && selectedChannel!.clients != nil && !selectedChannel!.clients!.isEmpty {
                List(selectedChannel!.clients!, id: \.self) { client in
                    Text(client.nick)
                }
            }
        }
        .frame(minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        .refreshable {
            Task {
                await getAgain()
                print("refreshed")
            }
        }
        .onAppear {
            Task {
                await initConnectToView()
            }
        }
        .toast(isPresenting: $showToast) {
            AlertToast(displayMode: .banner(.pop), type: toastType, title: toastTitle)
        }
    }

    func initConnectToView() async {
        if let channelList = await getChannels(instanceId: selectedInstance!.uuid) {
            channels = channelList
            let find = channelList.filter { channel in
                channel.clients != nil
            }
            var id = ""
            find.forEach { channel in
                if channel.clients == nil { return }
                if channel.clients!.contains(where: { client in
                    client.nick == "BotVerga"
                }) { id = channel.id }
            }
            selectedChannel = channelList.filter { channel in channel.id == id }.first
        } else {
            print("No channels received on init")
        }
    }

    func getAgain() async {
        await initConnectToView()
    }
}
