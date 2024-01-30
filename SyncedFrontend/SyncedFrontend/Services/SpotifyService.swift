import Foundation

class SpotifyService {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
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
            // TODO: Handle the case where code or state is missing
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
}
