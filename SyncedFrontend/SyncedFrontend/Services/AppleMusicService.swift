import Foundation
import StoreKit
import MusicKit

class AppleMusicService {
    private let apiService: APIService
    private let musicKitService: MusicKitService
    
    init(apiService: APIService, musicKitService: MusicKitService) {
        self.apiService = apiService
        self.musicKitService = musicKitService
    }
    
    func fetchUserToken() async throws -> String {
        do {
            let developerToken = try await getDeveloperToken()
            return try await requestUserToken(developerToken: developerToken)
        } catch {
            print("Failed to fetch user token: \(error)")
            throw AppleMusicServiceError.developerTokenRetrievalFailed
        }
    }
    
    func requestAuthorization() async -> SKCloudServiceAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SKCloudServiceController.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
    
    func editPlaylist(appleMusicPlaylistId: String, playlistId: String, songs: [SongMetadata]) async throws {
        do {
            let appleMusicSongs = try convertToMusicKitSongs(from: songs)
            let playlist = try await getAppleMusicPlaylistOrReplace(appleMusicPlaylistId: appleMusicPlaylistId, playlistId: playlistId)
            try await musicKitService.editPlaylist(songs: appleMusicSongs, to: playlist)
        } catch {
            print("Failed to edit playlist apple music id: \(appleMusicPlaylistId), backend id: \(playlistId)")
            throw AppleMusicServiceError.playlistEditFailed
        }
        
    }
    
    func createAppleMusicPlaylist(title: String, description: String, playlistId: String) async throws -> Playlist {
        do {
            let playlist = try await musicKitService.createPlaylist(title: title, description: description)
            try await updatePlaylistId(playlistId: playlistId, appleMusicPlaylistId: playlist.id.rawValue)
            return playlist
        } catch {
            print("Failed to create playlist for backend id: \(playlistId)")
            throw AppleMusicServiceError.playlistCreationFailed
        }
    }
    
    func getAppleMusicPlaylistOrReplace(appleMusicPlaylistId: String, playlistId: String) async throws -> Playlist {
        do {
            let playlist = try await musicKitService.getPlaylist(id: appleMusicPlaylistId)
            return playlist
        } catch {
            print("Playlist \(appleMusicPlaylistId) not found, replacing playlist backend id \(playlistId)")
            return try await replaceAppleMusicPlaylist(playlistId: playlistId)
        }
    }
    
    private func convertToMusicKitSongs(from songMetadataArray: [SongMetadata]) throws -> [Song] {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let songMetadataAppleMusicArray = songMetadataArray.map { song in
            return SongMetadataAppleMusic(id: song.appleMusicId ?? "", type: "track", attributes: Attributes(url: song.appleMusicUrl ?? ""))
        }
        
        do {
            let jsonData = try encoder.encode(songMetadataAppleMusicArray)
            let songs = try decoder.decode([Song].self, from: jsonData)
            
            return songs
        } catch {
            print("Error during song conversion: \(error)")
            
            throw AppleMusicServiceError.songConversionFailed
        }
    }
    
    private func getDeveloperToken() async throws -> String {
        do {
            let tokenResponse: DeveloperTokenResponse = try await apiService.makeGetRequest(endpoint: "/auth/apple-music/dev", model: DeveloperTokenResponse.self)
            return tokenResponse.appleMusicToken
        } catch {
            print("Failed to get developer token: \(error)")
            throw AppleMusicServiceError.developerTokenRetrievalFailed
        }
    }
    
    private func requestUserToken(developerToken: String) async throws -> String {
        let controller = SKCloudServiceController()
        return try await withCheckedThrowingContinuation { continuation in
            controller.requestUserToken(forDeveloperToken: developerToken) { userToken, error in
                DispatchQueue.main.async {
                    if let userToken = userToken {
                        continuation.resume(returning: userToken)
                    } else {
                        continuation.resume(throwing: AppleMusicServiceError.userTokenRequestFailed(error))
                    }
                }
            }
        }
    }
    
    private func replaceAppleMusicPlaylist(playlistId: String) async throws -> Playlist {
        do {
            let playlist = try await apiService.makeGetRequest(endpoint: "/collaborative-playlists/metadata/\(playlistId)", model: GetCollaborativePlaylistMetadataResponse.self)
            let newPlaylist = try await createAppleMusicPlaylist(title: playlist.metadata.title, description: playlist.metadata.description ?? "", playlistId: playlistId);
            return newPlaylist
        } catch {
            print("Failed to replace playlist for backend id: \(playlistId)")
            throw AppleMusicServiceError.playlistReplacementFailed
        }
    }
    
    private func updatePlaylistId(playlistId: String, appleMusicPlaylistId: String) async throws {
        do {
            let body = UpdateAppleMusicPlaylistIdRequest(playlistId: playlistId, appleMusicPlaylistId: appleMusicPlaylistId)
            let response = try await apiService.makePostRequest(endpoint: "/collaborative-playlists/metadata/apple-music-id", model: UpdateAppleMusicPlaylistIdResponse.self, body: body)
            if (response.appleMusicPlaylistId != appleMusicPlaylistId) {
                throw AppleMusicServiceError.playlistUpdateFailed
            }
        } catch {
            print("Failed to update playlist id for backend playlist id: \(playlistId)")
            throw error
        }
    }
}
