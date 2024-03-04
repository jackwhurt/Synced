import Foundation

class SpotifyService {
    private let apiService: APIService
    private let userService: UserService
    private let authorizationService: AuthenticationServiceProtocol
    
    init(apiService: APIService, userService: UserService, authorizationService: AuthenticationServiceProtocol) {
        self.apiService = apiService
        self.userService = userService
        self.authorizationService = authorizationService
    }
    
    func getSpotifyAuthURL() async throws -> URL {
        do {
            let response = try await apiService.makeGetRequest(endpoint: "/auth/spotify", model: GetSpotifyAuthResponse.self)
            guard let url = URL(string: response.location) else {
                throw SpotifyServiceError.failedToGetSpotifyAuthUrl
            }
            print("Successfully retrieved spotify auth url")
            
            return url
        } catch {
            print("Failed to retrieve spotify auth url")
            throw SpotifyServiceError.failedToGetSpotifyAuthUrl
        }
    }
    
    func exchangeSpotifyToken(code: String, state: String) async throws {
        let queryParams = [
            "code": code,
            "state": state
        ]
        do {
            _ = try await apiService.makePostRequest(endpoint: "/auth/spotify", model: ExchangeSpotifyTokenResponse.self, parameters: queryParams)
            print("Successfully exchanged for Spotify token")
        } catch {
            print("Failed to exchange for Spotify token")
            throw SpotifyServiceError.failedToExchangeSpotifyToken
        }
    }
    
    func handleAuthCallback(url: URL) async -> Bool {
        guard url.scheme == "syncedapp", let host = url.host, host == "callback" else {
            return false
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        guard let code = components?.queryItems?.first(where: { $0.name == "code" })?.value,
              let state = components?.queryItems?.first(where: { $0.name == "state" })?.value else {
            print("Code or state not set: failed to handle auth callback")
            return false
        }

        do {
            try await exchangeSpotifyToken(code: code, state: state)
            return true
        } catch {
            print("Failed to handle auth callback")
            return false
        }
    }
    
    func checkCurrentAuthorisationStatus() async -> Bool {
        do {
            let response = try await apiService.makeGetRequest(endpoint: "/auth/spotify/status", model: CheckCurrentAuthorisationStatusResponse.self)
            if let error = response.error {
                print("Server error: \(error)")
                throw SpotifyServiceError.failedToCheckAuthStatus
            }
            guard let isSpotifyConnected = response.isSpotifyConnected else { throw SpotifyServiceError.failedToCheckAuthStatus }
            print("Successfully retrieved spotify auth url")
            
            return isSpotifyConnected
        } catch {
            print("Failed to check authorisation status: \(error)")
            return false
        }
    }
}
