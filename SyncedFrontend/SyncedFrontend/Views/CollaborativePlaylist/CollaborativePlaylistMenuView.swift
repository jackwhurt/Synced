import SwiftUI

struct CollaborativePlaylistMenuView: View {
    @StateObject private var collaborativePlaylistMenuViewModel: CollaborativePlaylistMenuViewModel
    @State private var showingAddPlaylistSheet = false
    
    init() {
        let collaborativePlaylistService = DIContainer.shared.provideCollaborativePlaylistService()
        _collaborativePlaylistMenuViewModel = StateObject(wrappedValue: CollaborativePlaylistMenuViewModel(collaborativePlaylistService: collaborativePlaylistService))
    }
    
    var body: some View {
        NavigationView {
            List {
                addPlaylistSection
                playlistsSection
            }
            .navigationTitle("Playlists")
            .onAppear(perform: loadPlaylists)
        }
    }
    
    private var addPlaylistSection: some View {
        Section {
            Button(action: { showingAddPlaylistSheet = true }) {
                Label("Add New Playlist", systemImage: "plus")
            }
            .sheet(isPresented: $showingAddPlaylistSheet) {
                CreatePlaylistView(collaborativePlaylistViewModel: collaborativePlaylistMenuViewModel)
            }
        }
    }
    
    private var playlistsSection: some View {
        Section {
            ForEach(collaborativePlaylistMenuViewModel.playlists) { playlist in
                NavigationLink(destination: CollaborativePlaylistView(
                    playlistId: String(playlist.id.dropFirst(3)))) {
                    PlaylistView(playlist: playlist)
                }
            }
        }
    }
    
    private func loadPlaylists() {
        Task {
            await collaborativePlaylistMenuViewModel.loadPlaylists()
        }
    }
}

struct PlaylistView: View {
    let playlist: GetCollaborativePlaylistResponse
    
    var body: some View {
        HStack(spacing: 10) {
            AsyncImageLoader(urlString: playlist.coverImageUrl, width: 50, height: 50)
            
            // Title of the playlist
            Text(playlist.title)
                .foregroundColor(.primary)
                .font(.headline)
        }
    }
}

struct CollaborativePlaylistMenuView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(isLoggedIn: .constant(true))
    }
}
