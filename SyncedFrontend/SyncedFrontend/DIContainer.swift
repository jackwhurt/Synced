class DIContainer {
    static let shared = DIContainer()
    
    func provideMusicKitService() -> MusicKitService {
        return MusicKitService()
    }
    
    func provideKeychainService() -> KeychainService {
        return KeychainService()
    }
    
    func provideUserService() -> UserService {
        return UserService(apiService: provideAPIService())
    }
    
    func provideImageService() -> ImageService {
        return ImageService(apiService: provideAPIService())
    }
    
    func provideSongsService() -> SongService {
        return SongService(apiService: provideAPIService())
    }
    
    func provideAPIService() -> APIService {
        return APIService(keychainService: provideKeychainService(), authenticationService: provideAuthenticationService())
    }
    
    func provideAppleMusicService() -> AppleMusicService {
        return AppleMusicService(apiService: provideAPIService(), musicKitService: provideMusicKitService())
    }
    
    func provideActivityService() -> ActivityService {
        return ActivityService(apiService: provideAPIService(), appleMusicService: provideAppleMusicService())
    }
    
    func provideSpotifyService() -> SpotifyService {
        return SpotifyService(apiService: provideAPIService(), userService: provideUserService(), authorizationService: provideAuthenticationService())
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
