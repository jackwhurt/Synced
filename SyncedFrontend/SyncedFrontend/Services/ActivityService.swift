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
    // TODO: Percent encoding with api
    func resolveRequest(requestId: String, result: Bool, spotifyPlaylist: Bool) async throws {
        do {
            // Percent-encode the requestId to handle special characters like '#'
            guard let encodedRequestId = requestId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                throw ActivityServiceError.failedToResolveRequests
            }

            let endpoint = "/activities/requests/playlist?requestId=\(encodedRequestId)&result=\(result)&spotifyPlaylist=\(spotifyPlaylist)"
            let response = try await apiService.makePutRequest(endpoint: endpoint, model: ResolveRequestResponse.self)
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
