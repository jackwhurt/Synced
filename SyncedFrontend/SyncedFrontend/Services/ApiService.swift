import Foundation

class APIService {
    private let keychainService: KeychainService

    init(keychainService: KeychainService) {
        self.keychainService = keychainService
    }

    func makeGetRequest<T: Decodable>(endpoint: String, model: T.Type, parameters: [String: String]? = nil) async throws -> T {
        let urlWithParameters = appendQueryParameters(to: endpoint, parameters: parameters)
        return try await makeRequest(endpoint: urlWithParameters, httpMethod: "GET", model: model)
    }

    func makePostRequest<T: Decodable, B: Encodable>(endpoint: String, model: T.Type, body: B) async throws -> T {
        let bodyData = try JSONEncoder().encode(body)
        return try await makeRequest(endpoint: endpoint, httpMethod: "POST", model: model, body: bodyData)
    }

    private func makeRequest<T: Decodable>(endpoint: String, httpMethod: String, model: T.Type, body: Data? = nil) async throws -> T {
        guard let idToken = getIdToken() else {
            throw APIServiceError.tokenRetrievalFailed
        }

        guard let url = getAPIURL(for: endpoint) else {
            throw APIServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.addValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        
        if let body = body, httpMethod == "POST" {
            request.httpBody = body
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        print("Requesting: \(request)")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        do {
            let decodedData = try JSONDecoder().decode(T.self, from: data)
            print("Received: \(decodedData)")
            return decodedData
        } catch {
            print("Failed to decode data")
            throw APIServiceError.failedToDecodeResponse
        }
    }

    private func appendQueryParameters(to endpoint: String, parameters: [String: String]?) -> String {
        guard let parameters = parameters, var urlComponents = URLComponents(string: endpoint) else {
            return endpoint
        }
        
        urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        return urlComponents.url?.absoluteString ?? endpoint
    }

    private func getIdToken() -> String? {
        guard let idTokenData = keychainService.load(key: "idToken"), !idTokenData.isEmpty, let idToken = String(data: idTokenData, encoding: .utf8) else {
            return nil
        }
        return idToken
    }

    private func getAPIURL(for endpoint: String) -> URL? {
        guard let urlString = ProcessInfo.processInfo.environment["API_URL"], let url = URL(string: urlString + endpoint) else {
            return nil
        }
        return url
    }
}
