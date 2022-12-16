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
    @Binding var tracks: [Track]
    @Binding var selectedInstance: Instance?

    let columns = [
        GridItem(.adaptive(minimum: 80))
    ]
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(tracks, id: \.self) { track in
                    Button(action: {
                        Task {
                            await playAudioById(trackId: track.uuid, instanceId: selectedInstance!.uuid)
                        }
                    }) {
                        Text(track.title)
                    }
                }
            }
        }
    }
}
