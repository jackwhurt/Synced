import Foundation
import MusicKit

class CollaborativePlaylistService {
    private let apiService: APIService
    private let musicKitService: MusicKitService
    
    init(apiService: APIService, musicKitService: MusicKitService) {
        self.apiService = apiService
        self.musicKitService = musicKitService
    }
    
    func updatePlaylists() async throws {
        let updates: [UpdateSongsResponse]
        let timestampDict = ["timestamp": getLastUpdatedTimestamp()]
        let currentDate = Date()

        do {
            updates = try await getSongUpdates(parameters: timestampDict)
        } catch {
            print("Failed to retrieve song updates for timestamp: ", timestampDict["timestamp"] ?? "Unknown")
            throw CollaborativePlaylistServiceError.songUpdatesRetrievalFailed
        }
        
        var allUpdatesSuccessful = true
        for update in updates {
            do {
                let playlist = try await getPlaylistOrReplace(appleMusicPlaylistId: update.appleMusicPlaylistId, playlistId: update.playlistId)
                try await self.musicKitService.editPlaylist(songs: update.songs, to: playlist)
            } catch {
                allUpdatesSuccessful = false
                print("Failed to update playlist for backend id: \(update.playlistId): \(error)")
                throw CollaborativePlaylistServiceError.playlistUpdateFailed
            }
        }
        
        if (allUpdatesSuccessful) {
            updateLastUpdatedTimestamp(currentDate: currentDate)
            print("Updated last updated timestamp: \(currentDate)")
        }
    }
    
    func createPlaylist(title: String, description: String, playlistId: String) async throws -> Playlist {
        do {
            let playlist = try await musicKitService.createPlaylist(title: title, description: description)
            try await updatePlaylistId(playlistId: playlistId, appleMusicPlaylistId: playlist.id.rawValue)
            return playlist
        } catch {
            print("Failed to create playlist for backend id: \(playlistId)")
            throw CollaborativePlaylistServiceError.playlistCreationFailed
        }
    }
    
    func getPlaylists() async throws -> [CollaborativePlaylistResponse] {
        do {
            let response = try await apiService.makeGetRequest(endpoint: "/collaborative-playlists", model: [CollaborativePlaylistResponse].self)
            return response
        } catch {
            print("Failed to retrieve collaborative playlists")
            throw CollaborativePlaylistServiceError.playlistRetrievalFailed
        }
    }
    
    private func getPlaylistOrReplace(appleMusicPlaylistId: String, playlistId: String) async throws -> Playlist {
        do {
            let playlist = try await musicKitService.getPlaylist(id: appleMusicPlaylistId)
            return playlist
        } catch {
            print("Playlist \(appleMusicPlaylistId) not found, replacing playlist backend id \(playlistId)")
            return try await replacePlaylist(playlistId: playlistId)
        }
    }
    
    private func replacePlaylist(playlistId: String) async throws -> Playlist {
        do {
            let playlist = try await apiService.makeGetRequest(endpoint: "/collaborative-playlists/metadata/\(playlistId)", model: CollaborativePlaylistMetadataResponse.self)
            let newPlaylist = try await createPlaylist(title: playlist.metadata.title, description: playlist.metadata.description ?? "", playlistId: playlistId);
            return newPlaylist
        } catch {
            print("Failed to replace playlist for backend id: \(playlistId)")
            throw CollaborativePlaylistServiceError.playlistReplacementFailed
        }
    }
    
    private func getSongUpdates(parameters: [String: String]) async throws -> [UpdateSongsResponse] {
        return try await apiService.makeGetRequest(endpoint: "/collaborative-playlists/songs/apple-music", model: [UpdateSongsResponse].self, parameters: parameters)
    }
    
    private func updatePlaylistId(playlistId: String, appleMusicPlaylistId: String) async throws {
        do {
            let body = UpdateAppleMusicPlaylistIdRequest(playlistId: playlistId, appleMusicPlaylistId: appleMusicPlaylistId)
            let response = try await apiService.makePostRequest(endpoint: "/collaborative-playlists/metadata/apple-music-id", model: UpdateAppleMusicPlaylistIdResponse.self, body: body)
            if (response.appleMusicPlaylistId != appleMusicPlaylistId) {
                throw CollaborativePlaylistServiceError.playlistUpdateFailed
            }
        } catch {
            print("Failed to update playlist id for backend playlist id: \(playlistId)")
            throw error
        }
    }
    
    private func getLastUpdatedTimestamp() -> String {
        return UserDefaults.standard.object(forKey: "lastUpdatedTimestamp") as? String ?? ""
    }
    
    private func updateLastUpdatedTimestamp(currentDate: Date) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        
        UserDefaults.standard.set(formatter.string(from: currentDate), forKey: "lastUpdatedTimestamp")
    }
}
