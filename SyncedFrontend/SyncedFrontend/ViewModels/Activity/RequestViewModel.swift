import Foundation
import SwiftUI

class RequestViewModel: ObservableObject {
    @Binding var userRequests: [UserRequest]
    @Binding var playlistRequests: [PlaylistRequest]
    @Published var errorMessage: String? = nil

    private let activityService: ActivityService

    init(activityService: ActivityService, userRequests: Binding<[UserRequest]>, playlistRequests: Binding<[PlaylistRequest]>) {
        self.activityService = activityService
        self._playlistRequests = playlistRequests
        self._userRequests = userRequests
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
    
    func resolveRequest(request: PlaylistRequest, result: Bool, spotifyPlaylist: Bool, appleMusicPlaylist: Bool) async {
        do {
            try await activityService.resolveRequest(request: request, result: result, spotifyPlaylist: spotifyPlaylist, appleMusicPlaylist: appleMusicPlaylist)
            print("Successfully resolved request: \(request.requestId)")
            loadRequests()
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to complete the request. Please try again later."
            }
        }
    }
}
