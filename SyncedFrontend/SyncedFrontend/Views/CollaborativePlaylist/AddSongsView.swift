import SwiftUI

struct AddSongsView: View {
    @Binding var showSheet: Bool
    @State private var searchText = ""
    @StateObject private var addSongsViewModel: AddSongsViewModel
    @FocusState private var isTextFieldFocused: Bool
    
    init(showSheet: Binding<Bool>, songsToAdd: [SongMetadata]) {
        _showSheet = showSheet
        _addSongsViewModel = StateObject(wrappedValue: AddSongsViewModel(songService: DIContainer.shared.provideSongsService(), songsToAdd: songsToAdd))
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
                            await addSongsViewModel.convertSongs()
                        }
                    }
                }
            }
        }
        .onAppear {
            addSongsViewModel.dismissAction = {
                showSheet = false
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
                addSongsViewModel.toggleSongSelection(song: song)
            }) {
                Image(systemName: addSongsViewModel.selectedSongs.contains(song) ? "checkmark" : "plus")
            }
        }
    }
}

struct AddSongsView_Previews: PreviewProvider {
    static var previews: some View {
        AddSongsView(showSheet: .constant(true), songsToAdd: [])
    }
}
