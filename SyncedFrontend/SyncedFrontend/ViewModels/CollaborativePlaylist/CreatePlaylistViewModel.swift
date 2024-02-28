import Foundation

class CreatePlaylistViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var collaborators: [UserMetadata] = []
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
                self?.errorMessage = "Failed to create playlist, please try again later."
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
                self?.errorMessage = "Failed to retrieve users, please try again later."
            }
            return []
        }
    }
}
