//
//  ConnectTo.swift
//  Sinusbot Soundboard
//
//  Created by Bernardo Ruiz  on 16/12/22.
//

import SwiftUI

struct ConnectTo: View {
    @Binding var selectedInstance: Instance?
    @State var channels: [Channel] = []
    @State var selectedChannel: Channel = Channel(id: "placeholder", name: "Placeholder", parent: "asa", order: 0, disabled: false,clients: [])
    
    var body: some View {
        VStack {
            Picker("Channels",selection: $selectedChannel){
                ForEach(channels, id: \.self) {
                    Text($0.name).tag(Optional($0))
                }
            }.onReceive(selectedInstance.publisher.first()){ test in
                Task {
                    if let channelList =  await getChannels(instanceId: selectedInstance!.uuid) {
                        channels = channelList
                    } else {
                        print("No channels received on init")
                    }
                }
            }
            Button(action: {
                Task{
                    await changeChannel(instanceId: selectedInstance!.uuid, channelId:selectedChannel.id)
                }
            }){
                Text("Change")
            }.disabled(selectedChannel.id=="placeholder")
        }.onAppear {
            Task {
                await initConnectToView()
            }
        }
    }
    func initConnectToView() async {
        if let channelList =  await getChannels(instanceId: selectedInstance!.uuid) {
            channels = channelList
        } else {
            print("No channels received on init")
        }
    }
    
    func getAgain() {
        Task {
            if let channelList =  await getChannels(instanceId: selectedInstance!.uuid) {
                channels = channelList
            } else {
                print("No channels received on init")
            }
        }
    }
}

