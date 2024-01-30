import Foundation

class ProfileViewModel: ObservableObject {
    var isAppleMusicConnected = false
    
    private let appleMusicService: AppleMusicService
    private let spotifyService: SpotifyService
    
    init(appleMusicService: AppleMusicService, spotifyService: SpotifyService) {
        self.appleMusicService = appleMusicService
        self.spotifyService = spotifyService
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
}
