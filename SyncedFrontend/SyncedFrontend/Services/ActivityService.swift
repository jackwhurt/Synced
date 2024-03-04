import UserNotifications
import SwiftUI

// TODO: soft delete apple music playlist after unsuccessful resolve
class ActivityService {
    private let apiService: APIService
    private let appleMusicService: AppleMusicService
    
    init(apiService: APIService, appleMusicService: AppleMusicService) {
        self.apiService = apiService
        self.appleMusicService = appleMusicService
    }
    
    func getRequests() async throws -> Requests {
        do {
            let response = try await apiService.makeGetRequest(endpoint: "/activities/requests", model: GetRequestsResponse.self)
            if response.error != nil {
                throw ActivityServiceError.failedToGetRequests
            }
            print("Successfully received requests: \(response)")
            if let requests = response.requests {
                CachingService.shared.save(requests.userRequests, forKey: "userRequestsCache")
                CachingService.shared.save(requests.playlistRequests, forKey: "playlistRequestsCache")
            }
            
            return response.requests ?? Requests(playlistRequests: [], userRequests: [])
        } catch {
            print("Failed to retrieve requests")
            throw ActivityServiceError.failedToGetRequests
        }
    }
    
    // TODO: Rollback
    func resolveRequest(request: PlaylistRequest, result: Bool, spotifyPlaylist: Bool, appleMusicPlaylist: Bool) async throws {
        do {
            if appleMusicPlaylist {
                let _ = try await appleMusicService.createAppleMusicPlaylist(title: request.playlistTitle, description: request.playlistDescription, playlistId: request.playlistId)
                print("Successfully created apple music playlist for request: \(request.requestId)")
            }
            let parameters: [String: String] = [
                "requestId": request.requestId,
                "result": String(result),
                "spotifyPlaylist": String(spotifyPlaylist)
            ]
            let response = try await apiService.makePutRequest(endpoint: "/activities/requests/playlist", model: ResolveRequestResponse.self, parameters: parameters)
            if response.error != nil {
                throw ActivityServiceError.failedToResolveRequests
            }
            print("Successfully resolved requests: \(response)")
        } catch {
            print("Failed to resolve requests")
            throw ActivityServiceError.failedToResolveRequests
        }
    }
    
    func getNotifications() async throws -> [NotificationMetadata] {
        do {
            let response = try await apiService.makeGetRequest(endpoint: "/activities/notifications", model: GetNotificationsResponse.self)
            if response.error != nil {
                throw ActivityServiceError.failedToGetNotifications
            }
            print("Successfully received requests: \(response)")
            CachingService.shared.save(response.notifications, forKey: "notificationsCache")
            return response.notifications
        } catch {
            print("Failed to retrieve requests")
            throw ActivityServiceError.failedToGetNotifications
        }
    }
}
