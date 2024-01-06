import SwiftUI

struct CollaborativePlaylistView: View {
    @StateObject private var viewModel: CollaborativePlaylistViewModel
    @State private var showingAddPlaylistSheet = false

    init() {
        let collaborativePlaylistService = DIContainer.shared.provideCollaborativePlaylistService()
        _viewModel = StateObject(wrappedValue: CollaborativePlaylistViewModel(collaborativePlaylistService: collaborativePlaylistService))
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
                CreatePlaylistView()
            }
        }
    }

    private var playlistsSection: some View {
        Section {
            ForEach(viewModel.playlists) { playlist in
                PlaylistView(playlist: playlist)
            }
        }
    }

    private func loadPlaylists() {
        Task {
            await viewModel.loadPlaylists()
        }
    }
}

struct PlaylistView: View {
    let playlist: CollaborativePlaylistResponse

    var body: some View {
        Text(playlist.title)
    }
}

struct CollaborativePlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(isLoggedIn: .constant(true))
    }
}
