class DIContainer {
    static let shared = DIContainer()

    func provideAuthenticationService() -> AuthenticationServiceProtocol {
        do {
            return try AuthenticationService(keychainService: provideKeychainService())
        } catch {
            print("Error: \(error)")
            return FallbackAuthenticationService()
        }
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
}
