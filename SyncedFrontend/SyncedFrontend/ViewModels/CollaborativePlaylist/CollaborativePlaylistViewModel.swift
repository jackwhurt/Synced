import Foundation

class CollaborativePlaylistViewModel: ObservableObject {
    private let collaborativePlaylistService: CollaborativePlaylistService
    @Published private(set) var playlists: [CollaborativePlaylistResponse] = []

    init(collaborativePlaylistService: CollaborativePlaylistService) {
        self.collaborativePlaylistService = collaborativePlaylistService
    }

    func loadPlaylists() async {
        do {
            let loadedPlaylists = try await collaborativePlaylistService.getPlaylists()
            print("Loaded playlists: \(loadedPlaylists)")
            DispatchQueue.main.async {
                self.playlists = loadedPlaylists
            }
        } catch {
            DispatchQueue.main.async {
                // Update some state here to show error message
                print("Failed to load playlists: \(error)")
            }
        }
    }
    
    func createPlaylist() async {
        
    }
}
