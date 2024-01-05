import Foundation
import StoreKit

class AppleMusicService {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func fetchUserToken() async throws -> String {
        do {
            let developerToken = try await getDeveloperToken()
            return try await requestUserToken(developerToken: developerToken)
        } catch {
            print("Failed to fetch user token: \(error)")
            throw AppleMusicServiceError.developerTokenRetrievalFailed
        }
    }
    
    func requestAuthorization() async -> SKCloudServiceAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SKCloudServiceController.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
    
    private func getDeveloperToken() async throws -> String {
        do {
            let tokenResponse: DeveloperTokenResponse = try await apiService.makeGetRequest(endpoint: "/auth/apple-music/dev", model: DeveloperTokenResponse.self)
            return tokenResponse.appleMusicToken
        } catch {
            print("Failed to get developer token: \(error)")
            throw AppleMusicServiceError.developerTokenRetrievalFailed
        }
    }
    
    private func requestUserToken(developerToken: String) async throws -> String {
        let controller = SKCloudServiceController()
        return try await withCheckedThrowingContinuation { continuation in
            controller.requestUserToken(forDeveloperToken: developerToken) { userToken, error in
                DispatchQueue.main.async {
                    if let userToken = userToken {
                        continuation.resume(returning: userToken)
                    } else {
                        continuation.resume(throwing: AppleMusicServiceError.userTokenRequestFailed(error))
                    }
                }
            }
        }
    }
}
