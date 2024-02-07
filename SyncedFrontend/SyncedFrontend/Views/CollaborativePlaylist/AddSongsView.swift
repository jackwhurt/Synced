import SwiftUI

struct AddSongsView: View {
    @Binding var showSheet: Bool
    @State private var searchText = ""
    @State private var showErrorAlert = false
    @StateObject private var addSongsViewModel: AddSongsViewModel
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.presentationMode) var presentationMode
    
    init(showSheet: Binding<Bool>, songsToAdd: Binding<[SongMetadata]>, playlistSongs: [SongMetadata]) {
        _showSheet = showSheet
        _addSongsViewModel = StateObject(wrappedValue: AddSongsViewModel(songService: DIContainer.shared.provideSongsService(), playlistSongs: playlistSongs, songsToAdd: songsToAdd))
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
                                showErrorAlert = addSongsViewModel.errorMessage != nil
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
                            showErrorAlert = addSongsViewModel.errorMessage != nil
                        }
                    }
                }
            }
            .alert(isPresented: $showErrorAlert, content: errorAlert)
        }
        .onAppear {
            addSongsViewModel.dismissAction = {
                showSheet = false
            }
        }
        .accentColor(Color("SyncedBlue"))
    }
    
    
    private func errorAlert() -> Alert {
        Alert(
            title: Text("Error"),
            message: Text(addSongsViewModel.errorMessage ?? "Unknown error"),
            dismissButton: .default(Text("OK"), action: {
                // Clear the error message here
                addSongsViewModel.errorMessage = nil
            })
        )
    }
}

struct SongRowToAdd: View {
    @ObservedObject var addSongsViewModel: AddSongsViewModel
    let song: SongMetadata
    
    var body: some View {
        HStack(spacing: 10) {
            MusicAsyncImageLoader(urlString: song.coverImageUrl, width: 40, height: 40)
            VStack(alignment: .leading, spacing: 0) {
                Text(song.title)
                    .bold()
                    .foregroundColor(.primary)
                    .font(.system(size: 14))
                Text(song.artist ?? "")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
            }
            Spacer()
            Button(action: {
                addSongsViewModel.toggleSongSelection(song: song)
            }) {
                Image(systemName: addSongsViewModel.containsSong(song: song) ? "checkmark" : "plus")
            }
        }
    }
}

struct AddSongsView_Previews: PreviewProvider {
    @State static var dummySongsToAdd: [SongMetadata] = []
    
    static var previews: some View {
        AddSongsView(showSheet: .constant(true), songsToAdd: $dummySongsToAdd, playlistSongs: [])
    }
}

