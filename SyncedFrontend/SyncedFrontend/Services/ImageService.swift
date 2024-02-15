import Foundation
import SwiftUI

class ImageService {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func saveImage(playlistId: String? = nil, userIdBool: String? = nil, image: UIImage, s3Url: String?) async throws -> String {
        do {
            let urlString = try await getImageUploadUrl(playlistId: playlistId, userIdBool: userIdBool)
            print("Successfully received url: \(urlString)")
            try await uploadImage(uploadUrl: urlString, image: image, s3Url: s3Url)
            print("Successfully saved image")
            return urlString
        } catch {
            print("Failed to save image: \(error)")
            throw ImageServiceError.failedToUploadImage
        }
    }
    
    private func getImageUploadUrl(playlistId: String? = nil, userIdBool: String? = nil) async throws -> String {
        do {
            var params: [String: String] = [:]
            if let playlistId = playlistId {
                params["playlistId"] = playlistId
            }
            if let userId = userIdBool {
                params["userIdBool"] = userId
            }
            
            let response = try await apiService.makeGetRequest(endpoint: "/image", model: GetImageUrlResponse.self, parameters: params)
            if let error = response.error {
                print("Failed to get upload url server side: \(error)")
                throw ImageServiceError.failedToGetImageUploadUrl
            }
            
            guard let uploadUrl = response.uploadUrl else {
                throw ImageServiceError.uploadUrlNotFound
            }
            print("Successfully retrieved image url: \(response)")
            
            return uploadUrl
        } catch {
            print("Failed to get upload url: \(error)")
            throw ImageServiceError.failedToGetImageUploadUrl
        }
    }
    
    private func uploadImage(uploadUrl: String, image: UIImage, s3Url: String?) async throws {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            throw ImageServiceError.imageDataConversionFailed
        }
        guard let url = URL(string: uploadUrl) else {
            throw ImageServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        
        do {
            let response = try await uploadData(request: request, data: imageData)
            print("Successfully uploaded image to S3: \(response)")
        } catch {
            print("Failed to upload image to S3: \(error)")
            throw ImageServiceError.failedToUploadImage
        }
    }
    
    private func uploadData(request: URLRequest, data: Data) async throws -> String {
        do {
            let (responseData, response) = try await URLSession.shared.upload(for: request, from: data)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIServiceError.failedToDecodeResponse
            }
            
            print("Status code: \(httpResponse.statusCode)")
            print("Headers: \(httpResponse.allHeaderFields)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let responseBody = String(data: responseData, encoding: .utf8) {
                    print("Error response body: \(responseBody)")
                }
                throw APIServiceError.failedToUploadToS3
            }
            
            if let responseBody = String(data: responseData, encoding: .utf8) {
                return responseBody
            } else {
                throw APIServiceError.failedToDecodeResponse
            }
        } catch {
            print("Failed to upload image to S3: \(error)")
            throw APIServiceError.failedToUploadToS3
        }
    }
}
