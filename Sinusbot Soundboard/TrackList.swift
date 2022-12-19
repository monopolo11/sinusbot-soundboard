//
//  TrackList.swift
//  Sinusbot Soundboard
//
//  Created by Bernardo Ruiz  on 15/12/22.
//

import SwiftUI

/* struct TrackList: View {
     @State var tracks: [Track] = []
     @State var selectedInstance: String = ""
     var body: some View {
         ScrollView {
             VStack {
                 ForEach(tracks, id: \.self) { track in
                     Button(track.title, action: {
                         Task {
                             await playAudioById(trackId: track.uuid, instanceId: selectedInstance)
                         }
                     })
                 }
             }
         }
     }
 }

 struct TrackList_Previews: PreviewProvider {
     static var previews: some View {
         TrackList()
     }
 } */

struct TrackList: View {
    @Binding var selectedInstance: Instance?
    @Binding var token: String?
    @State var searchText: String = ""
    @State var allTracks: [Track] = []
    
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
        ScrollView {
            LazyVGrid(columns: columns, spacing: 40) {
                ForEach(filteredAudios, id: \.self) { track in
                    Button(action: {
                        Task {
                            await playAudioById(trackId: track.uuid, instanceId: selectedInstance!.uuid)
                        }
                    }) {
                        Text(track.title)
                            .truncationMode(.tail)
                            .foregroundColor(.white)
                            .padding()
                            .scaledToFit()
                    }
                    .frame(width: 100, height: 40, alignment: .center)
                    .background(Color(red: 0, green: 0, blue: 0.8))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.top,20)
        .searchable(text: $searchText,placement: .navigationBarDrawer(displayMode: .automatic))
        .onAppear {
            Task {
               await initTracksView()
            }
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
