class ActivityService {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
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
    
    // TODO: Apple music playlists
    func resolveRequest(requestId: String, result: Bool, spotifyPlaylist: Bool) async throws {
        do {
            let parameters: [String: String] = [
                "requestId": requestId,
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
