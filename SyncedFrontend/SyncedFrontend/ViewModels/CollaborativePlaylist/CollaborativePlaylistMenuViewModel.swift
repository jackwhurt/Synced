import Foundation

class CollaborativePlaylistMenuViewModel: ObservableObject {
    @Published var playlists: [GetCollaborativePlaylistResponse] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    private let collaborativePlaylistService: CollaborativePlaylistService
    
    init(collaborativePlaylistService: CollaborativePlaylistService) {
        self.collaborativePlaylistService = collaborativePlaylistService
        loadPlaylistsFromCache()
    }
    
    func loadPlaylists() async {
        do {
            let loadedPlaylists = try await collaborativePlaylistService.getPlaylists()
            DispatchQueue.main.async {
                self.playlists = loadedPlaylists
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to retrieve playlist updates."
                print("Failed to load playlists: \(error)")
            }
        }
    }
    
    private func loadPlaylistsFromCache() {
        if let cachedPlaylists = CachingService.shared.load(forKey: "collaborativePlaylists", type: [GetCollaborativePlaylistResponse].self) {
            self.playlists = cachedPlaylists
        } else {
            DispatchQueue.main.async {
                Task {
                    self.isLoading = true
                    await self.loadPlaylists()
                    self.isLoading = false
                }
            }
        }
    }
}
