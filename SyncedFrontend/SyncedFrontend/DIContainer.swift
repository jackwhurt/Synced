class DIContainer {
    static let shared = DIContainer()
    
    func provideMusicKitService() -> MusicKitService {
        return MusicKitService()
    }
    
    func provideKeychainService() -> KeychainService {
        return KeychainService()
    }
    
    func provideAPIService() -> APIService {
        return APIService(keychainService: provideKeychainService())
    }
    
    func provideUserService() -> UserService {
        return UserService(apiService: provideAPIService())
    }
    
    func provideSongsService() -> SongService {
        return SongService(apiService: provideAPIService())
    }
    
    func provideSpotifyService() -> SpotifyService {
        return SpotifyService(apiService: provideAPIService())
    }
    
    func provideAppleMusicService() -> AppleMusicService {
        return AppleMusicService(apiService: provideAPIService(), musicKitService: provideMusicKitService())
    }
    
    func provideActivityService() -> ActivityService {
        return ActivityService(apiService: provideAPIService(), appleMusicService: provideAppleMusicService())
    }
    
    func provideCollaborativePlaylistService() -> CollaborativePlaylistService {
        return CollaborativePlaylistService(apiService: provideAPIService(), appleMusicService: provideAppleMusicService(), musicKitService: provideMusicKitService())
    }
    
    func provideAuthenticationService() -> AuthenticationServiceProtocol {
        do {
            return try AuthenticationService(keychainService: provideKeychainService())
        } catch {
            print("Error: \(error)")
            return FallbackAuthenticationService()
        }
    }
}
