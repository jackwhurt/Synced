import Foundation

class CollaborativePlaylistMenuViewModel: ObservableObject {
    @Published var playlists: [GetCollaborativePlaylistResponse] = [] {
        didSet {
            CachingService.shared.save(playlists, forKey: "collaborativePlaylists")
        }
    }
    
    private let collaborativePlaylistService: CollaborativePlaylistService

    init(collaborativePlaylistService: CollaborativePlaylistService) {
        self.collaborativePlaylistService = collaborativePlaylistService
        loadPlaylistsFromCache()
    }

    private func loadPlaylistsFromCache() {
        if let cachedPlaylists: [GetCollaborativePlaylistResponse] = CachingService.shared.load(forKey: "collaborativePlaylists", type: [GetCollaborativePlaylistResponse].self) {
            self.playlists = cachedPlaylists
        }
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
                // TODO: Error msg
                print("Failed to load playlists: \(error)")
            }
        }
    }
}
