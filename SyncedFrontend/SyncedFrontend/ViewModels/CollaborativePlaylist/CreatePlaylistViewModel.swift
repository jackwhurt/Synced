import Foundation

class CreatePlaylistViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var collaborators: [String] = []
    @Published var newCollaborator: String = ""
    @Published var errorMessage: String?
    @Published var createSpotifyPlaylist: Bool = false
    @Published var createAppleMusicPlaylist: Bool = false
    private let collaborativePlaylistService: CollaborativePlaylistService
    private let collaborativePlaylistViewModel: CollaborativePlaylistViewModel

    init(collaborativePlaylistService: CollaborativePlaylistService, collaborativePlaylistViewModel: CollaborativePlaylistViewModel) {
        self.collaborativePlaylistService = collaborativePlaylistService
        self.collaborativePlaylistViewModel = collaborativePlaylistViewModel
    }
    
    func addNewCollaborator() {
        if !newCollaborator.isEmpty {
            collaborators.append(newCollaborator)
            newCollaborator = "" // Reset the field
        }
    }

    func deleteCollaborator(at offsets: IndexSet) {
        collaborators.remove(atOffsets: offsets)
    }

    func save() async {
        let playlist = CollaborativePlaylist(title: title, description: description, songs: [])
        let request = CreateCollaborativePlaylistRequest(playlist: playlist, collaborators: collaborators, spotifyPlaylist: createSpotifyPlaylist, appleMusicPlaylist: createAppleMusicPlaylist)
        
        do {
            let backendPlaylistId = try await collaborativePlaylistService.createPlaylist(request: request)
            print("Successfully created playlist id: \(backendPlaylistId)")
        } catch {
            print("Failed to save playlist: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to create playlist, please try again later"
            }
        }
        
        await collaborativePlaylistViewModel.loadPlaylists()
    }

}
