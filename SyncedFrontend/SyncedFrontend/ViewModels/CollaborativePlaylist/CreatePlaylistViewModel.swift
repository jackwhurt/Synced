import Foundation

class CreatePlaylistViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var collaborators: [UserMetadata] = []
    @Published var newCollaborator: UserMetadata?
    @Published var usernameQuery: String = ""
    @Published var errorMessage: String?
    @Published var createSpotifyPlaylist: Bool = false
    @Published var createAppleMusicPlaylist: Bool = false
    private let collaborativePlaylistService: CollaborativePlaylistService
    private let userService: UserService
    private let collaborativePlaylistViewModel: CollaborativePlaylistMenuViewModel

    // TODO: Refactor viewmodel out
    init(collaborativePlaylistService: CollaborativePlaylistService, userService: UserService, collaborativePlaylistViewModel: CollaborativePlaylistMenuViewModel) {
        self.collaborativePlaylistService = collaborativePlaylistService
        self.userService = userService
        self.collaborativePlaylistViewModel = collaborativePlaylistViewModel
    }
    
    func addNewCollaborator() {
        guard let collaborator = newCollaborator else {
            return
        }
        collaborators.append(collaborator)
        newCollaborator = nil
    }

    func deleteCollaborator(at offsets: IndexSet) {
        collaborators.remove(atOffsets: offsets)
    }

    func save() async {
        let playlist = CollaborativePlaylist(title: title, description: description, songs: [])
        let request = CreateCollaborativePlaylistRequest(playlist: playlist,
            collaborators: collaborators.map { $0.userId },
            spotifyPlaylist: createSpotifyPlaylist,
            appleMusicPlaylist: createAppleMusicPlaylist)
        
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
    
    func searchUsers(usernameQuery: String, page: Int) async -> [UserMetadata] {
        do {
            let response = try await userService.getUsers(usernameQuery: usernameQuery, page: page)
            return response.users
        } catch {
            print("Failed to retrieve users")
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to retrieve users, please try again later"
            }
            return []
        }
    }
    
    func getWarningMessage(spotify: Bool, appleMusic: Bool) -> String {
        switch (spotify, appleMusic) {
        case (false, false):
            return "Neither Spotify nor Apple Music is connected."
        case (false, true):
            return "Spotify is not connected."
        case (true, false):
            return "Apple Music is not connected."
        default:
            return ""
        }
    }
}
