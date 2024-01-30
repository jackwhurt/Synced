import Foundation
import SwiftUI

class ProfileViewModel: ObservableObject {
    @Binding var isLoggedIn: Bool
    var isAppleMusicConnected = false
    
    private let appleMusicService: AppleMusicService
    private let spotifyService: SpotifyService
    private let authenticationService: AuthenticationServiceProtocol
    
    init(isLoggedIn: Binding<Bool>, appleMusicService: AppleMusicService, spotifyService: SpotifyService, authenticationService: AuthenticationServiceProtocol) {
        _isLoggedIn = isLoggedIn
        self.appleMusicService = appleMusicService
        self.spotifyService = spotifyService
        self.authenticationService = authenticationService
        self.isAppleMusicConnected = appleMusicService.checkCurrentAuthorizationStatus()
    }
    
    func requestAuthentication() async -> Bool {
        let status = await appleMusicService.requestAuthorization()

        switch status {
        case .authorized:
            print("Successfully requested authorisation")
            return true
        case .denied, .notDetermined, .restricted:
            print("Authorization status: \(status)")
        @unknown default:
            print("Unexpected authorization status")
        }
        
        return false
    }
    
    func getSpotifyAuthURL() async -> URL? {
        do {
            let url = try await spotifyService.getSpotifyAuthURL()
            print("Successfully retrieved Spotify auth url: \(url)")
            
            return url
        } catch {
            print("Failed to get Spotify auth url: \(error)")
        }
        
        return nil
    }
    
    func logout() {
        authenticationService.logoutUser { [weak self] result in
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
}
