import SwiftUI

struct AddSongsView: View {
    @StateObject private var addSongsViewModel: AddSongsViewModel
    @State private var searchText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    init() {
        _addSongsViewModel = StateObject(wrappedValue: AddSongsViewModel(songService: DIContainer.shared.provideSongsService()))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    // Search bar
                    TextField("Search songs", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isTextFieldFocused)
                        .submitLabel(.search)
                        .onSubmit {
                            Task {
                                await addSongsViewModel.searchSpotifyApi(query: searchText, page: 0)
                            }
                        }

                    // Cancel button appears when TextField is focused
                    if isTextFieldFocused {
                        Button("Cancel") {
                            isTextFieldFocused = false
                            searchText = ""
                        }
                    }
                }
                .padding()

                List {
                    ForEach(addSongsViewModel.spotifySongs, id: \.self) { song in
                        SongRowToAdd(addSongsViewModel: addSongsViewModel, song: song)
                    }
                }
            }
            .navigationBarTitle("Add Songs", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await addSongsViewModel.saveSongs()
                        }
                    }
                }
            }
        }
    }
}


struct SongRowToAdd: View {
    @ObservedObject var addSongsViewModel: AddSongsViewModel
    let song: SongMetadata
    
    var body: some View {
        HStack(spacing: 10) {
            AsyncImageLoader(urlString: song.coverImageUrl, width: 40, height: 40)
            VStack(alignment: .leading, spacing: 0) {
                Text(song.title)
                    .bold()
                    .foregroundColor(.primary)
                    .font(.system(size: 14))
                Text(song.artist)
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
            }
            Spacer()
            Button(action: {
                addSongsViewModel.toggleSongSelection(spotifyUri: song.spotifyUri)
            }) {
                Image(systemName: addSongsViewModel.selectedSongUris.contains(song.spotifyUri) ? "checkmark" : "plus")
            }
        }
    }
}

struct AddSongsView_Previews: PreviewProvider {
    static var previews: some View {
        AddSongsView()
    }
}
