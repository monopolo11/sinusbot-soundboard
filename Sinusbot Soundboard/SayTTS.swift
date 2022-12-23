//
//  ConnectTo.swift
//  Sinusbot Soundboard
//
//  Created by Bernardo Ruiz  on 16/12/22.
//

import AlertToast
import SwiftUI

struct SayTTS: View {
    @Binding var selectedInstance: Instance?
    @State var channels: [Channel] = []
    @State var selectedChannel: Channel?
    @State var text: String = ""
    @State var locale: LocaleObject = Locales.first!
    @State private var showToast: Bool = false
    @State private var toastTitle: String = ""
    @State private var toastType: AlertToast.AlertType = .regular

    var body: some View {
        VStack(alignment: .center) {
            if(selectedChannel != nil) {
                Text(selectedChannel!.name)
                    .font(.headline)
            }
            Form {
                Section {
                    TextField("Text for the bot to say",text:$text)
                    Picker("Locales",selection: $locale) {
                        ForEach(Locales,id: \.self) { local in
                            Text(local.language)
                        }
                    }
                    Button(action: {Task { await handleSay()}}){
                        Text("Say")
                    }
                    .disabled(text.isEmpty)
                    
                }
                Section(header:  Text(selectedChannel?.clients?.isEmpty ?? true ? "No users connected" : "Connected users")) {
                   
                    if selectedChannel != nil && selectedChannel!.clients != nil && !selectedChannel!.clients!.isEmpty {
                        List(selectedChannel!.clients!.sorted(by: { $0.nick < $1.nick }), id: \.self) { client in
                            Text(client.nick)
                        }
                    }
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
        .onChange(of: selectedInstance) { _ in
            Task {
                await getAgain()
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
                    let bots = ["BotVerga","Development Bot"]
                    return bots.contains(client.nick)
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
    
    func handleSay() async {
        let success: Bool = await playTTS(text: text, locale: locale.locale, instanceId: selectedInstance!.uuid)
        if success {
            toastTitle = "Playing TTS"
            toastType = .complete(.green)
            showToast.toggle()
        }else {
            toastTitle = "There was an error, try again"
            toastType = .error(.red)
            showToast.toggle()
        }
    }
}
