import Foundation

class CollaborativePlaylistMenuViewModel: ObservableObject {
    private let collaborativePlaylistService: CollaborativePlaylistService
    @Published var playlists: [GetCollaborativePlaylistResponse] = []

    init(collaborativePlaylistService: CollaborativePlaylistService) {
        self.collaborativePlaylistService = collaborativePlaylistService
    }

    // TODO: Call loadplaylists everytime you go back. Then can refactor viewmodel out of create playlist viewmodel
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
}
