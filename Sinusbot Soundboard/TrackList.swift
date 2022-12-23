//
//  TrackList.swift
//  Sinusbot Soundboard
//
//  Created by Bernardo Ruiz  on 15/12/22.
//

import AlertToast
import SwiftUI

struct TrackList: View {
    @Binding var selectedInstance: Instance?
    @Binding var token: String?
    @State var searchText: String = ""
    @State var allTracks: [Track] = []
    @State private var showToast: Bool = false

    var filteredAudios: [Track] {
        if searchText.isEmpty {
            return allTracks
        } else {
            return allTracks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }

    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    var body: some View {
        if allTracks.isEmpty {
            VStack(alignment: .center) {
                ProgressView()
            }
            .frame(alignment: .center)
            .refreshable {
                Task {
                    await initTracksView()
                }
            }
        }
        ScrollView {
            LazyVGrid(columns: columns, spacing: 40) {
                ForEach(filteredAudios, id: \.self) { track in
                    Button(action: {
                        Task {
                            let success = await playAudioById(trackId: track.uuid, instanceId: selectedInstance!.uuid)
                            if success {
                                showToast.toggle()
                            }
                        }
                    }) {
                        Text(track.title)
                            .foregroundColor(.white)
                            .padding()
                            .lineLimit(2)

                    }
                    .frame(width: 100, height: 100, alignment: .center)
                    .background(Color(red: 0, green: 0, blue: 0.8))
                    .clipShape(Capsule())
                }
            }
            .padding()
        }
        .searchable(text: $searchText)
        .onAppear {
            Task {
                await initTracksView()
            }
        }
        .refreshable {
            Task {
                await initTracksView()
            }
        }
        .toast(isPresenting: $showToast) {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: "Playing Sound")
        }
    }

    func initTracksView() async {
        if token == nil { await login() }
        if let trackList = await getTracks() {
            allTracks = trackList
        } else {
            print("Failed to get tracks on appear")
        }
    }
}
