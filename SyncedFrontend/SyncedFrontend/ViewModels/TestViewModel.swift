import SwiftUI
import StoreKit
import MusicKit

class TestViewModel: ObservableObject {
    @Published var isLoggedIn = true
    private let authenticationService: AuthenticationServiceProtocol?
    private let appleMusicService: AppleMusicService
    private let musicKitService: MusicKitService
    private let collaborativePlaylistService: CollaborativePlaylistService

    init(authenticationService: AuthenticationServiceProtocol, appleMusicService: AppleMusicService, musicKitService: MusicKitService, collaborativePlaylistService: CollaborativePlaylistService) {
        self.authenticationService = authenticationService
        self.appleMusicService = appleMusicService
        self.musicKitService = musicKitService
        self.collaborativePlaylistService = collaborativePlaylistService
    }

    func logout() {
        authenticationService?.logoutUser { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.isLoggedIn = false
                case .failure(let error):
                    print("Logout error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func createPlaylist() async {
        do {
            let id = try await collaborativePlaylistService.createPlaylist(title: "title bruh", description: "description123", playlistId: "bd613977-19a3-4441-a8c5-3049c7e59ae3")
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
