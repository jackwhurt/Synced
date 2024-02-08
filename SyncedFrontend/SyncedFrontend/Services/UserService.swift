import SwiftUI

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
    
    func getUserById(userId: String) async throws -> UserMetadata {
        do {
            let response = try await apiService.makeGetRequest(endpoint: "/users/\(userId)", model: GetUserByIdResponse.self)

            if let error = response.error {
                print("Server error: \(error)")
                throw UserServiceError.failedToRetrieveUser
            }
            guard let user = response.user else {
                throw UserServiceError.failedToRetrieveUser
            }
            
            CachingService.shared.save(user, forKey: "UserMetadata_\(userId)")
            
            return user
        } catch {
            print("Failed to get user \(userId)")
            throw UserServiceError.failedToRetrieveUser
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
