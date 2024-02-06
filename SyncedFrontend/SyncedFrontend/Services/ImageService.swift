import Foundation
import SwiftUI

class ImageService {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func getImageUploadUrl(playlistId: String?, userIdBool: String?) async throws -> String {
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
    
    func uploadImage(uploadUrl: String, image: UIImage) async throws {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            throw ImageServiceError.imageDataConversionFailed
        }
        
        do {
            let response = try await apiService.uploadToS3(endpoint: uploadUrl, imageData: imageData)
            print("Successfully uploaded image to S3: \(response)")
        } catch {
            print("Failed to upload image to S3: \(error)")
            throw ImageServiceError.failedToUploadImage
        }
    }
}
