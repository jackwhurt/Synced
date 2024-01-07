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
    
    func editSongs(appleMusicPlaylistId: String?, playlistId: String, songsToDelete: [SongMetadata], songsToAdd: [SongMetadata], allSongs: [SongMetadata]) async throws {
        do {
//            TODO: Dont perform if lists are empty
//            TODO: Actually save songs
//            apiService.makePostRequest(endpoint: "collaborative-playlists/songs", model: AddSongsResponse.self, body: request)
            try await apiService.makeDeleteRequest(endpoint: "/collaborative-playlists/songs", model: DeleteSongsResponse.self, body: DeleteSongsRequest(playlistId: playlistId, songs: songsToDelete))
            if let appleMusicPlaylistId = appleMusicPlaylistId {
                try await appleMusicService.editPlaylist(appleMusicPlaylistId: appleMusicPlaylistId, playlistId: playlistId, songs: allSongs)
            }
        } catch {
            print("Failed to edit songs")
            throw CollaborativePlaylistServiceError.failedToEditSongs
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
