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
}
