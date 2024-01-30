import Foundation

class AppSettings: ObservableObject {
    @Published var isAppleMusicConnected: Bool = false
    @Published var isSpotifyConnected: Bool = false
    private let appleMusicService: AppleMusicService

    init(appleMusicService: AppleMusicService) {
        self.appleMusicService = appleMusicService
        self.isAppleMusicConnected = appleMusicService.checkCurrentAuthorizationStatus()
    }
}
