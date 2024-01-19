import SwiftUI

struct CollaborativePlaylistView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var collaborativePlaylistViewModel: CollaborativePlaylistViewModel
    @State private var showErrorAlert = false
    @State private var selectedOption: String? = nil
    @State private var showingAddSongsSheet = false
    @State private var showingDeleteConfirmation = false

    init(playlistId: String) {
        let viewModel = CollaborativePlaylistViewModel(
            playlistId: playlistId,
            collaborativePlaylistService: DIContainer.shared.provideCollaborativePlaylistService(), authenticationService: DIContainer.shared.provideAuthenticationService()
        )
        _collaborativePlaylistViewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        List {
            if let playlistMetadata = collaborativePlaylistViewModel.playlistMetadata {
                PlaylistHeaderView(metadata: playlistMetadata)
                    .listRowSeparator(.hidden)
                
                SongList(songs: collaborativePlaylistViewModel.songsToDisplay,
                         isEditing: collaborativePlaylistViewModel.isEditing,
                         onAddSongs: {
                            showingAddSongsSheet = true
                         },
                         onDelete: { indexSet in
                            guard let index = indexSet.first else { return }
                            let songToDelete = collaborativePlaylistViewModel.songsToDisplay[index]
                            collaborativePlaylistViewModel.deleteSong(song: songToDelete)
                        })

                if collaborativePlaylistViewModel.songsToDisplay.isEmpty {
                    Text("Playlist is empty")
                        .foregroundColor(.secondary)
                        .listRowSeparator(.hidden)
                }
            } else if collaborativePlaylistViewModel.errorMessage == nil {
                playlistLoadingView()
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(collaborativePlaylistViewModel.isEditing)
        .toolbar { navigationBarMenu() }
        .sheet(isPresented: $showingAddSongsSheet) {
            AddSongsView(showSheet: $showingAddSongsSheet, songsToAdd: $collaborativePlaylistViewModel.songsToAdd)
        }
        .onAppear {
            collaborativePlaylistViewModel.dismissAction = {
                self.presentationMode.wrappedValue.dismiss()
            }
            loadPlaylist()
        }
        .alert(isPresented: $showErrorAlert, content: errorAlert)
        .alert(isPresented: $showingDeleteConfirmation, content: deletePlaylistConfirmationAlert)

    }
    
    private func dismissView() {
        presentationMode.wrappedValue.dismiss()
    }
    
    // Playlist Loading View
    private func playlistLoadingView() -> some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }
    
    // Navigation Bar Menu
    private func navigationBarMenu() -> some ToolbarContent {
        Group {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                if collaborativePlaylistViewModel.isEditing {
                    Button("Cancel") {
                        collaborativePlaylistViewModel.cancelChanges()
                    }
                }
            }
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if collaborativePlaylistViewModel.isEditing {
                    Button("Save") {
                        Task{
                            await collaborativePlaylistViewModel.saveChanges()
                            showErrorAlert = collaborativePlaylistViewModel.errorMessage != nil
                        }
                    }
                } else {
                    Menu {
                        Button("Edit Playlist") {
                            collaborativePlaylistViewModel.setEditingTrue()
                        }

                        if collaborativePlaylistViewModel.playlistOwner {
                            Button("Delete Playlist") {
                                showingDeleteConfirmation = true
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private func loadPlaylist() {
        Task {
            await collaborativePlaylistViewModel.loadPlaylist()
            showErrorAlert = collaborativePlaylistViewModel.errorMessage != nil
        }
    }
    
    private func errorAlert() -> Alert {
        let dismissButton: Alert.Button = .default(Text("OK"), action: {
            if collaborativePlaylistViewModel.autoDismiss {
                presentationMode.wrappedValue.dismiss()
            }
        })

        return Alert(title: Text("Error"),
                     message: Text(collaborativePlaylistViewModel.errorMessage ?? "Unknown error"),
                     dismissButton: dismissButton)
    }
    
    private func deletePlaylistConfirmationAlert() -> Alert {
        Alert(
            title: Text("Delete Playlist"),
            message: Text("Are you sure you want to delete this playlist?"),
            primaryButton: .destructive(Text("Delete")) {
                Task {
                    await collaborativePlaylistViewModel.deletePlaylist()
                }
            },
            secondaryButton: .cancel()
        )
    }

}

struct PlaylistHeaderView: View {
    var metadata: PlaylistMetadata
    
    var body: some View {
        VStack {
            AsyncImageLoader(urlString: metadata.coverImageUrl, width: 300, height: 300)
            Text(metadata.title)
                .font(.headline)
                .bold()
                .multilineTextAlignment(.center)
            Text(metadata.description ?? "")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SongList: View {
    var songs: [SongMetadata]
    var isEditing: Bool
    var onAddSongs: () -> Void
    var onDelete: (IndexSet) -> Void
    
    var body: some View {
        if isEditing {
            Button(action: onAddSongs) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Songs")
                }
            }
        }
        ForEach(songs, id: \.title) { song in
            SongRow(song: song)
        }
        .onDelete(perform: isEditing ? onDelete : nil)
    }
}

struct SongRow: View {
    var song: SongMetadata
    
    var body: some View {
        HStack(spacing: 10) {
            AsyncImageLoader(urlString: song.coverImageUrl, width: 40, height: 40)
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
        }
    }
}

// Preview Provider and Sample Data
struct CollaborativePlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        CollaborativePlaylistView(playlistId: "")
    }
}
