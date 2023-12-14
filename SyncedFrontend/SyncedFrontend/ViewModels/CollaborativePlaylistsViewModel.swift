import SwiftUI
import StoreKit
import MusicKit

class CollaborativePlaylistsViewModel: ObservableObject {
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
    
    func createPlaylist() async {
        do {
            let id = try await musicKitService.createPlaylist(withTitle: "title bruh", description: "description123", authorDisplayName: "bruh author")
            let mySong = "{\"id\":\"1482041830\",\"type\":\"songs\",\"attributes\":{\"url\":\"https://music.apple.com/us/album/cloud-9/1482041821?i=1482041830\"}}"
            guard let jsonData = mySong.data(using: .utf8) else {
                print("Error: Cannot create Data from jsonString")
                return
            }
            print("Id: ", id)
            let decoder = JSONDecoder()
            
            let song = try decoder.decode(Song.self, from: jsonData)
            try await musicKitService.addSongToPlaylist(song: song, to: id)
            try await musicKitService.editPlaylist(songs: [], to: id)
        } catch {
            print("Failed: ", error)
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
