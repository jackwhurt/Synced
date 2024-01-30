class ActivityService {
    private let apiService: APIService
    private let appleMusicService: AppleMusicService
    
    init(apiService: APIService, appleMusicService: AppleMusicService) {
        self.apiService = apiService
        self.appleMusicService = appleMusicService
    }
    
    func getRequests() async throws -> Requests {
        do {
            let response = try await apiService.makeGetRequest(endpoint: "/activities/requests", model: GetRequestsResponse.self)
            if response.error != nil {
                throw ActivityServiceError.failedToGetRequests
            }
            print("Successfully received requests: \(response)")
            return response.requests ?? Requests(playlistRequests: [], userRequests: [])
        } catch {
            print("Failed to retrieve requests")
            throw ActivityServiceError.failedToGetRequests
        }
    }
    
    // TODO: Rollback
    func resolveRequest(request: PlaylistRequest, result: Bool, spotifyPlaylist: Bool, appleMusicPlaylist: Bool) async throws {
        do {
            if appleMusicPlaylist {
                let response = try await appleMusicService.createAppleMusicPlaylist(title: request.playlistTitle, description: request.playlistDescription, playlistId: request.playlistId)
                print("Successfully created apple music playlist for request: \(request.requestId)")
            }
            let parameters: [String: String] = [
                "requestId": request.requestId,
                "result": String(result),
                "spotifyPlaylist": String(spotifyPlaylist)
            ]
            let response = try await apiService.makePutRequest(endpoint: "/activities/requests/playlist", model: ResolveRequestResponse.self, parameters: parameters)
            if response.error != nil {
                throw ActivityServiceError.failedToResolveRequests
            }
            print("Successfully resolved requests: \(response)")
        } catch {
            print("Failed to resolve requests")
            throw ActivityServiceError.failedToResolveRequests
        }
    }
}
