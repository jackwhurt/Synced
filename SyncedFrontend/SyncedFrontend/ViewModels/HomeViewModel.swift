import SwiftUI
import StoreKit
import MusicKit

class HomeViewModel: ObservableObject {
    @Published var isLoggedIn = true
    private let authenticationService: AuthenticationServiceProtocol?
    private let appleMusicService: AppleMusicService
    private let musicKitService: MusicKitService

    init(authenticationService: AuthenticationServiceProtocol, appleMusicService: AppleMusicService, musicKitService: MusicKitService) {
        self.authenticationService = authenticationService
        self.appleMusicService = appleMusicService
        self.musicKitService = musicKitService
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
    
    // TODO: Get playlistId programmatically
    func createPlaylist() async {
        do {
            let id = try await musicKitService.createPlaylist(withTitle: "title bruh", description: "description123", authorDisplayName: "bruh author")
            print("Id: ", id)
        } catch {
            print("Failed: ", error)
        }
    }
    
    func connectAppleMusic() async {
        await authenticateAndRequestToken()
    }

    private func authenticateAndRequestToken() async {
        let status = await appleMusicService.requestAuthorization()

        switch status {
        case .authorized:
            await requestUserToken()
        case .denied, .notDetermined, .restricted:
            // Handle different cases as needed
            print("Authorization status: \(status)")
        @unknown default:
            print("Unexpected authorization status")
        }
    }


    private func requestUserToken() async {
        do {
            let token = try await appleMusicService.fetchUserToken()
            print("User Token: \(token)")
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}
