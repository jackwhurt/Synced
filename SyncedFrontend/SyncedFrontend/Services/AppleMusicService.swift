import Foundation
import StoreKit

class AppleMusicService {
    private let apiService: APIService

    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    // Public function to handle user token request
    func fetchUserToken(completion: @escaping (Result<String, Error>) -> Void) {
        getDeveloperToken { [weak self] result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let developerToken):
                self?.requestUserToken(developerToken: developerToken, completion: completion)
            }
        }
    }

    // Request authorization to access Apple Music
    func requestAuthorization(completion: @escaping (SKCloudServiceAuthorizationStatus) -> Void) {
        SKCloudServiceController.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status)
            }
        }
    }

    // TODO: First check keychain and expiry timestamp
    // Function to retrieve Apple Music Developer Token from the API
    private func getDeveloperToken(completion: @escaping (Result<String, Error>) -> Void) {
        apiService.makeGetRequest(endpoint: "/auth/apple-music/dev", model: DeveloperTokenResponse.self) { result in
            switch result {
            case .failure(let error):
                print("Failed to retrieve Apple Music dev token")
                completion(.failure(error))
            case .success(let tokenResponse):
                completion(.success(tokenResponse.appleMusicToken))
            }
        }
    }

    // Function to request a user token for Apple Music using the developer token
    private func requestUserToken(developerToken: String, completion: @escaping (Result<String, Error>) -> Void) {
        let controller = SKCloudServiceController()
        controller.requestUserToken(forDeveloperToken: developerToken) { userToken, error in
            DispatchQueue.main.async {
                if let userToken = userToken {
                    completion(.success(userToken))
                } else {
                    completion(.failure(error ?? NSError(domain: "AppleMusicService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])))
                }
            }
        }
    }
}
