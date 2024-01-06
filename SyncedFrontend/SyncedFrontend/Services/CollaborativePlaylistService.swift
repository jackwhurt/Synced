import Foundation
import MusicKit

class CollaborativePlaylistService {
    private let apiService: APIService
    private let appleMusicService: AppleMusicService
    
    init(apiService: APIService, appleMusicService: AppleMusicService) {
        self.apiService = apiService
        self.appleMusicService = appleMusicService
    }
    
    func getPlaylists() async throws -> [GetCollaborativePlaylistResponse] {
        do {
            let response = try await apiService.makeGetRequest(endpoint: "/collaborative-playlists", model: [GetCollaborativePlaylistResponse].self)
            return response
        } catch {
            print("Failed to retrieve collaborative playlists")
            throw CollaborativePlaylistServiceError.playlistRetrievalFailed
        }
    }
    
    func getPlaylistById(playlistId: String) async throws -> GetCollaborativePlaylistByIdResponse {
        do {
            let response = try await apiService.makeGetRequest(endpoint: "/collaborative-playlists/\(playlistId)", model: GetCollaborativePlaylistByIdResponse.self)
            return response
        } catch {
            print("Failed to retrieve collaborative playlist")
            throw CollaborativePlaylistServiceError.playlistRetrievalFailed
        }
    }
    
    func createPlaylist(request: CreateCollaborativePlaylistRequest) async throws -> String {
        do {
            let backendPlaylistId = try await createBackendPlaylist(request: request)
            print("Successfully created backend playlist, id: \(backendPlaylistId)")
            
            var appleMusicPlaylist: Playlist
            if request.appleMusicPlaylist {
                appleMusicPlaylist = try await appleMusicService.createAppleMusicPlaylist(title: request.playlist.title, description: request.playlist.description ?? "", playlistId: backendPlaylistId)
                print("Successfully created Apple Music playlist, id: \(appleMusicPlaylist.id.rawValue)")
            }

            return backendPlaylistId
        } catch {
            print("Failed to create playlist \(request.playlist.title)")
            throw CollaborativePlaylistServiceError.playlistCreationFailed
        }
    }

    
    private func createBackendPlaylist(request: CreateCollaborativePlaylistRequest) async throws -> String {
        do {
            let response = try await apiService.makePostRequest(endpoint: "/collaborative-playlists", model: CreateCollaborativePlaylistResponse.self, body: request)
            return response.id
        } catch {
            print("Failed to create playlist \(request.playlist.title) on the backend")
            throw CollaborativePlaylistServiceError.backendPlaylistCreationFailed
        }
    }
}
