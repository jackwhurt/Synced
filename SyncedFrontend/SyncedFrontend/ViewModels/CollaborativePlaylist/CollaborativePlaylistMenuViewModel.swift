import Foundation

class CollaborativePlaylistMenuViewModel: ObservableObject {
    @Published var playlists: [GetCollaborativePlaylistResponse] = []
    private let collaborativePlaylistService: CollaborativePlaylistService

    init(collaborativePlaylistService: CollaborativePlaylistService) {
        self.collaborativePlaylistService = collaborativePlaylistService
        loadPlaylistsFromCache()
    }
    
    func loadPlaylists() async {
        do {
            let loadedPlaylists = try await collaborativePlaylistService.getPlaylists()
            print("Loaded playlists")
            DispatchQueue.main.async {
                self.playlists = loadedPlaylists
            }
        } catch {
            DispatchQueue.main.async {
                // TODO: Error msg
                print("Failed to load playlists: \(error)")
            }
        }
    }
    
    private func loadPlaylistsFromCache() {
        if let cachedPlaylists: [GetCollaborativePlaylistResponse] = CachingService.shared.load(forKey: "collaborativePlaylists", type: [GetCollaborativePlaylistResponse].self) {
            self.playlists = cachedPlaylists
        }
    }
}
