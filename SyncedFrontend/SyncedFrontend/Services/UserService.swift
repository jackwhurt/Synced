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
    
    func registerUserForApns(deviceToken: String) async {
        do {
            let parameters: [String: String] = ["deviceToken": deviceToken]
            let response = try await apiService.makePostRequest(endpoint: "/users/apns", model: RegisterUserForApnsResponse.self, parameters: parameters)
            if response.error != nil {
                throw UserServiceError.failedToRegisterForApns
            }
        } catch {
            print("Failed to register for APNS: \(error)")
        }
    }
}
