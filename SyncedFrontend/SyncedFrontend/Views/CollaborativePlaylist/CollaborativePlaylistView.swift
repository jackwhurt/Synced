import SwiftUI

struct CollaborativePlaylistView: View {
    @StateObject private var collaborativePlaylistViewModel: CollaborativePlaylistViewModel
    @State private var showErrorAlert = false
    @State private var selectedOption: String? = nil
    @State private var showingAddSongsSheet = false
    @Environment(\.presentationMode) var presentationMode
    
    init(playlistId: String) {
        _collaborativePlaylistViewModel = StateObject(wrappedValue: CollaborativePlaylistViewModel(playlistId: playlistId, collaborativePlaylistService: DIContainer.shared.provideCollaborativePlaylistService()))
    }
    
    var body: some View {
        List {
            if let playlist = collaborativePlaylistViewModel.playlist {
                PlaylistHeaderView(metadata: playlist.metadata)
                    .listRowSeparator(.hidden)
                if !playlist.songs.isEmpty {
                    SongList(songs: playlist.songs,
                             isEditing: collaborativePlaylistViewModel.isEditing,
                             onAddSongs: {
                        showingAddSongsSheet = true
                    },
                             onDelete: { indexSet in
                        guard let index = indexSet.first else { return }
                        let songToDelete = playlist.songs[index]
                        collaborativePlaylistViewModel.deleteSong(song: songToDelete)
                    })
                } else {
                    Text("Playlist is empty")
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
        .sheet(isPresented: $showingAddSongsSheet) { AddSongsView() }
        .onAppear(perform: loadPlaylist)
        .alert(isPresented: $showErrorAlert, content: errorAlert)
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
                        }
                    }
                } else {
                    Menu {
                        Button("Edit Playlist") {
                            collaborativePlaylistViewModel.setEditingTrue()
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
        Alert(title: Text("Error"),
              message: Text(collaborativePlaylistViewModel.errorMessage ?? "Unknown error"),
              dismissButton: .default(Text("OK"), action: {
            presentationMode.wrappedValue.dismiss()
        }))
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
                Text(song.artist)
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

let samplePlaylistResponse = GetCollaborativePlaylistByIdResponse(
    playlistId: "id", appleMusicPlaylistId: nil,
    metadata: PlaylistMetadata(title: "Collaborative Hits", description: "A collection of top collaborative tracks.",
                               coverImageUrl: ""),
    songs: (1...50).map { index in
        SongMetadata(
            songId: nil,
            title: "Song \(index)",
            artist: "Artist \(index)",
            spotifyUri: nil,
            appleMusicUrl: nil,
            appleMusicId: nil,
            coverImageUrl: "https://i.scdn.co/image/ab67616d0000b2736aa1a0eae5f023675b4e9818"
        )
    }
)
