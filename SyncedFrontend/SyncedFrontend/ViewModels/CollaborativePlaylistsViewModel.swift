import SwiftUI
import StoreKit

class CollaborativePlaylistsViewModel: ObservableObject {
    @Published var isLoggedIn = true
    private let authenticationService: AuthenticationServiceProtocol?
    private let appleMusicService: AppleMusicService

    init(authenticationService: AuthenticationServiceProtocol, appleMusicService: AppleMusicService) {
        self.authenticationService = authenticationService
        self.appleMusicService = appleMusicService
    }

    func logout() {
        authenticationService?.logoutUser { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.isLoggedIn = false
                case .failure(let error):
                    print("Logout error: \(error.localizedDescription)")
                    // Handle error scenario
                }
            }
        }
    }
    
    func connectAppleMusic() {
        authenticateAndRequestToken()
    }

    private func authenticateAndRequestToken() {
        appleMusicService.requestAuthorization { [weak self] status in
            switch status {
            case .authorized:
                self?.requestUserToken()
            case .denied, .notDetermined, .restricted:
                // Handle different cases as needed
                print("Authorization status: \(status)")
            @unknown default:
                print("Unexpected authorization status")
            }
        }
    }

    private func requestUserToken() {
        appleMusicService.fetchUserToken { result in
            switch result {
            case .success(let token):
                print("User Token: \(token)")
                // Use the token for API requests
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
                // Handle error
            }
        }
    }
}
