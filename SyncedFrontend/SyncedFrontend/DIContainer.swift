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
    
    func provideAppleMusicService() -> AppleMusicService {
        return AppleMusicService(apiService: provideAPIService())
    }
    
    func provideCollaborativePlaylistService() -> CollaborativePlaylistService {
        return CollaborativePlaylistService(apiService: provideAPIService(), musicKitService: provideMusicKitService())
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
