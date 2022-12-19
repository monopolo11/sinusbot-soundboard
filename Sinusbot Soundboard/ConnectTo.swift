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
    @State var selectedChannel: Channel?
    
    var body: some View {
        VStack {
            Picker("Channels",selection: $selectedChannel){
                Text("Select a Channel").tag(nil as Channel?)
                ForEach(channels, id: \.self) {
                    Text($0.name).tag($0 as Channel?)
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
                    await changeChannel(instanceId: selectedInstance!.uuid, channelId:selectedChannel!.id)
                }
            }){
                Text("Change")
            }.disabled(selectedChannel==nil)
            Text("Connected users")
            if(selectedChannel != nil && selectedChannel!.clients != nil && !selectedChannel!.clients!.isEmpty) {
                ScrollView {
                    ForEach(selectedChannel!.clients!, id: \.self) { client in
                        Text(client.nick)
                    }
                }
            }
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

