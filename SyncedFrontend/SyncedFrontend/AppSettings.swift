import Foundation

class AppSettings: ObservableObject {
    @Published var isAppleMusicConnected: Bool = false
    @Published var isSpotifyConnected: Bool = false
    
    private let appleMusicService: AppleMusicService
    private let spotifyService: SpotifyService
    
    init(appleMusicService: AppleMusicService, spotifyService: SpotifyService) {
        self.appleMusicService = appleMusicService
        self.spotifyService = spotifyService
        setStreamingServiceConnections()
    }
    
    func setStreamingServiceConnections()  {
        Task {
            self.isAppleMusicConnected = appleMusicService.checkCurrentAuthorizationStatus()
            self.isSpotifyConnected = await spotifyService.checkCurrentAuthorisationStatus()
        }
    }
}
