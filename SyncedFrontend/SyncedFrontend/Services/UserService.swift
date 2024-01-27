class UserService {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func getUsers(usernameQuery: String, page: Int) async throws -> GetUsersResponse {
        do {
            let response = try await apiService.makeGetRequest(endpoint: "/users?username=\(usernameQuery)&page=\(page)", model: GetUsersResponse.self)
            return response
        } catch {
            print("Failed to get users for query \(usernameQuery), page \(page)")
            throw UserServiceError.failedToRetrieveUsers
        }
    }
}
