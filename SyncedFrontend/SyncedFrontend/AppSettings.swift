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
            let appleMusicConnected = appleMusicService.checkCurrentAuthorizationStatus()
            let spotifyConnected = await spotifyService.checkCurrentAuthorisationStatus()
            
            DispatchQueue.main.async { [weak self] in
                self?.isAppleMusicConnected = appleMusicConnected
                self?.isSpotifyConnected = spotifyConnected
            }
        }
    }
}
