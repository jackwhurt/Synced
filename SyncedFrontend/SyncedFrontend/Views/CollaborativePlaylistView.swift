import SwiftUI

struct CollaborativePlaylistView: View {
    // Use @StateObject if this view is responsible for creating the ViewModel
    @StateObject private var collaborativePlaylistViewModel: CollaborativePlaylistViewModel
    
    init() {
        let collaborativePlaylistViewModel = CollaborativePlaylistViewModel(
            collaborativePlaylistService: DIContainer.shared.provideCollaborativePlaylistService()
        )
        
        _collaborativePlaylistViewModel = StateObject(wrappedValue: collaborativePlaylistViewModel)
    }

    var body: some View {
        NavigationView {
            List(collaborativePlaylistViewModel.playlists) { playlist in
                PlaylistView(playlist: playlist)
            }
            .navigationTitle("Playlists")
            .onAppear {
                // Load playlists when the view appears
                Task {
                    await collaborativePlaylistViewModel.loadPlaylists()
                }
            }
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
