import Foundation

class RequestViewModel: ObservableObject {
    @Published var userRequests: [UserRequest] = []
    @Published var playlistRequests: [PlaylistRequest] = []
    @Published var errorMessage: String? = nil

    private let activityService: ActivityService
    private let appleMusicService: AppleMusicService

    init(activityService: ActivityService, appleMusicService: AppleMusicService) {
        self.activityService = activityService
        self.appleMusicService = appleMusicService
        loadRequests()
    }

    func loadRequests() {
        Task {
            do {
                let requests = try await activityService.getRequests()
                DispatchQueue.main.async {
                    self.userRequests = requests.userRequests
                    self.playlistRequests = requests.playlistRequests
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load requests. Please try again later."
                }
            }
        }
    }
    
    // TODO: Rollback
    func resolveRequest(request: PlaylistRequest, result: Bool, spotifyPlaylist: Bool, appleMusicPlaylist: Bool) async {
        do {
            if appleMusicPlaylist {
                let response = try await appleMusicService.createAppleMusicPlaylist(title: request.playlistTitle, description: request.playlistDescription, playlistId: request.playlistId)
                print("Successfully created apple music playlist for request: \(request.requestId)")
            }
            try await activityService.resolveRequest(requestId: request.requestId, result: result, spotifyPlaylist: spotifyPlaylist)
            print("Successfully resolved request: \(request.requestId)")
            loadRequests()
        } catch {
            self.errorMessage = "Failed to complete the request. Please try again later."
        }
    }
}
