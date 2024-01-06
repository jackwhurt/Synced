import SwiftUI

struct CollaborativePlaylistView: View {
    @StateObject private var collaborativePlaylistViewModel: CollaborativePlaylistViewModel
    @State private var showErrorAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    init(playlistId: String) {
        _collaborativePlaylistViewModel = StateObject(wrappedValue: CollaborativePlaylistViewModel(playlistId: playlistId, collaborativePlaylistService: DIContainer.shared.provideCollaborativePlaylistService()))
    }
    
    var body: some View {
        ScrollView {
            if let playlist = collaborativePlaylistViewModel.playlist {
                VStack {
                    PlaylistHeaderView(metadata: playlist.metadata)
                    SongList(songs: playlist.songs)
                }
            } else if collaborativePlaylistViewModel.errorMessage == nil {
                ProgressView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadPlaylist)
        .alert(isPresented: $showErrorAlert, content: errorAlert)
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
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct SongList: View {
    var songs: [SongMetadata]
    
    var body: some View {
        ForEach(songs, id: \.title) { song in
            SongRow(song: song)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(
                    Divider().padding(.leading, 16), alignment: .bottom
                )
        }
    }
}

struct SongRow: View {
    var song: SongMetadata
    
    var body: some View {
        HStack(spacing: 10) {
            AsyncImageLoader(urlString: song.coverImageUrl, width: 35, height: 35)
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
        .padding(.horizontal, 16)
    }
}

// Preview Provider and Sample Data
struct CollaborativePlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        CollaborativePlaylistView(playlistId: "")
    }
}

let samplePlaylistResponse = GetCollaborativePlaylistByIdResponse(
    playlistId: "id",
    metadata: PlaylistMetadata(title: "Collaborative Hits", description: "A collection of top collaborative tracks.",
                               coverImageUrl: ""),
    songs: (1...50).map { index in
        SongMetadata(
            title: "Song \(index)",
            artist: "Artist \(index)",
            spotifyUri: nil,
            appleMusicUrl: nil,
            appleMusicId: nil,
            coverImageUrl: "https://i.scdn.co/image/ab67616d0000b2736aa1a0eae5f023675b4e9818"
        )
    }
)
