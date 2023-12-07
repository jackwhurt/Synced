import Foundation

class APIService {
    private let keychainService: KeychainService

    init(keychainService: KeychainService) {
        self.keychainService = keychainService
    }
    
    func makeGetRequest<T: Decodable>(endpoint: String, model: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        makeRequest(endpoint: endpoint, httpMethod: "GET", model: model, completion: completion)
    }

    func makePostRequest<T: Decodable>(endpoint: String, model: T.Type, body: Data?, completion: @escaping (Result<T, Error>) -> Void) {
        makeRequest(endpoint: endpoint, httpMethod: "POST", model: model, body: body, completion: completion)
    }

    private func makeRequest<T: Decodable>(endpoint: String, httpMethod: String, model: T.Type, body: Data? = nil, completion: @escaping (Result<T, Error>) -> Void) {
        guard let idToken = getIdToken() else {
            completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve ID Token"])))
            return
        }

        guard let url = getAPIURL(for: endpoint) else {
            completion(.failure(NSError(domain: "APIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.addValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        if let body = body {
            request.httpBody = body
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "APIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            do {
                let decodedData = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
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
