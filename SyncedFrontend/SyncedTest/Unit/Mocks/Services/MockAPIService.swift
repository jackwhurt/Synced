import Foundation

class MockAPIService: APIServiceProtocol {
    var makeGetRequestCallCount = 0
    var makeGetRequestLastParams: (endpoint: String, parameters: [String: String]?)?
    
    var makePutRequestCallCount = 0
    var makePutRequestLastParams: (endpoint: String, parameters: [String: String]?)?
    
    var makePostRequestWithBodyCallCount = 0
    var makePostRequestWithBodyLastParams: (endpoint: String, body: Encodable, parameters: [String: String]?)?
    
    var makePostRequestCallCount = 0
    var makePostRequestLastParams: (endpoint: String, parameters: [String: String]?)?
    
    var makeDeleteRequestCallCount = 0
    var makeDeleteRequestLastParams: (endpoint: String, body: Encodable)?
    
    var uploadToS3CallCount = 0
    var uploadToS3LastParams: (endpoint: String, imageData: Data)?
    
    var makeGetRequestHandler: ((String, Any.Type, [String: String]?) async throws -> Any)?
    var makePutRequestHandler: ((String, Any.Type, [String: String]?) async throws -> Any)?
    var makePostRequestWithBodyHandler: ((String, Any.Type, Encodable, [String: String]?) async throws -> Any)?
    var makePostRequestHandler: ((String, Any.Type, [String: String]?) async throws -> Any)?
    var makeDeleteRequestHandler: ((String, Any.Type, Encodable) async throws -> Any)?
    var uploadToS3Handler: ((String, Data) async throws -> String)?
    
    func makeGetRequest<T>(endpoint: String, model: T.Type, parameters: [String: String]?) async throws -> T where T: Decodable {
        makeGetRequestCallCount += 1
        makeGetRequestLastParams = (endpoint, parameters)
        guard let handler = makeGetRequestHandler else {
            fatalError("Handler not set for makeGetRequest.")
        }
        return try await handler(endpoint, model, parameters) as! T
    }

    func makePutRequest<T>(endpoint: String, model: T.Type, parameters: [String: String]?) async throws -> T where T: Decodable {
        makePutRequestCallCount += 1
        makePutRequestLastParams = (endpoint, parameters)
        guard let handler = makePutRequestHandler else {
            fatalError("Handler not set for makePutRequest.")
        }
        return try await handler(endpoint, model, parameters) as! T
    }

    func makePostRequest<T, B>(endpoint: String, model: T.Type, body: B, parameters: [String: String]?) async throws -> T where T: Decodable, B: Encodable {
        makePostRequestWithBodyCallCount += 1
        makePostRequestWithBodyLastParams = (endpoint, body, parameters)
        guard let handler = makePostRequestWithBodyHandler else {
            fatalError("Handler not set for makePostRequest with body.")
        }
        return try await handler(endpoint, model, body, parameters) as! T
    }

    func makePostRequest<T>(endpoint: String, model: T.Type, parameters: [String: String]?) async throws -> T where T: Decodable {
        makePostRequestCallCount += 1
        makePostRequestLastParams = (endpoint, parameters)
        guard let handler = makePostRequestHandler else {
            fatalError("Handler not set for makePostRequest.")
        }
        return try await handler(endpoint, model, parameters) as! T
    }

    func makeDeleteRequest<T, B>(endpoint: String, model: T.Type, body: B) async throws -> T where T: Decodable, B: Encodable {
        makeDeleteRequestCallCount += 1
        makeDeleteRequestLastParams = (endpoint, body)
        guard let handler = makeDeleteRequestHandler else {
            fatalError("Handler not set for makeDeleteRequest.")
        }
        return try await handler(endpoint, model, body) as! T
    }

    func uploadToS3(endpoint: String, imageData: Data) async throws -> String {
        uploadToS3CallCount += 1
        uploadToS3LastParams = (endpoint, imageData)
        guard let handler = uploadToS3Handler else {
            fatalError("Handler not set for uploadToS3.")
        }
        return try await handler(endpoint, imageData)
    }
}
