import Foundation

class CollaborativePlaylistViewModel: ObservableObject {
    @Published var playlist: GetCollaborativePlaylistByIdResponse?
    @Published var errorMessage: String? // Add an error message property

    private let playlistId: String
    private let collaborativePlaylistService: CollaborativePlaylistService

    init(playlistId: String, collaborativePlaylistService: CollaborativePlaylistService) {
        self.playlistId = playlistId
        self.collaborativePlaylistService = collaborativePlaylistService
    }

    func loadPlaylist() async {
        do {
            let fetchedPlaylist = try await collaborativePlaylistService.getPlaylistById(playlistId: playlistId)
            DispatchQueue.main.async {
                self.playlist = fetchedPlaylist
            }
        } catch {
            print("Failed to load playlist: \(playlistId)")
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to load playlist, please try again later"
            }
        }
    }
}
