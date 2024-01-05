import Foundation
import MusicKit

//TODO: Choose error strat and stick with it
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

        do {
            updates = try await getSongUpdates(parameters: timestampDict)
        } catch {
            print("Failed to retrieve song updates for timestamp: ", timestampDict["timestamp"] ?? "Unknown")
            throw CollaborativePlaylistServiceError.songUpdatesRetrievalFailed(error)
        }
        
        var allUpdatesSuccessful = true
        for update in updates {
            do {
                let playlist = try await getPlaylistOrReplace(appleMusicPlaylistId: update.appleMusicPlaylistId, playlistId: update.playlistId)
                try await self.musicKitService.editPlaylist(songs: update.songs, to: playlist)
            } catch {
                print("Failed to update playlist \(update.appleMusicPlaylistId): \(error)")
                allUpdatesSuccessful = false
                throw CollaborativePlaylistServiceError.playlistUpdateFailed(update.appleMusicPlaylistId, error)
            }
        }
        
        if allUpdatesSuccessful {
            updateLastUpdatedTimestamp()
        }
    }
    
    func createPlaylist(title: String, description: String, playlistId: String) async throws -> Playlist {
        do {
            let playlist = try await musicKitService.createPlaylist(title: title, description: description)
            try await updatePlaylistId(playlistId: playlistId, appleMusicPlaylistId: playlist.id.rawValue)
            return playlist
        } catch {
            throw CollaborativePlaylistServiceError.playlistCreationFailed("For backend playlist id: \(playlistId)", error)
        }
    }
    
    private func getPlaylistOrReplace(appleMusicPlaylistId: String, playlistId: String) async throws -> Playlist {
        do {
            let playlist = try await musicKitService.getPlaylist(id: appleMusicPlaylistId)
            return playlist
        } catch {
            return try await replacePlaylist(playlistId: playlistId)
        }
    }
    
    private func replacePlaylist(playlistId: String) async throws -> Playlist {
        do {
            // TODO: metadata request not decoding data
            let playlist = try await apiService.makeGetRequest(endpoint: "/collaborative-playlists/metadata/\(playlistId)", model: CollaborativePlaylistMetadataResponse.self)
            let newPlaylist = try await createPlaylist(title: playlist.metadata.title, description: playlist.metadata.description ?? "", playlistId: playlistId);
            return newPlaylist
        } catch {
            throw CollaborativePlaylistServiceError.playlistReplacementFailed("For backend playlist id: \(playlistId)", error)
        }
    }
    
    
    private func getSongUpdates(parameters: [String: String]) async throws -> [UpdateSongsResponse] {
        // TODO: REVERT
//        return try await apiService.makeGetRequest(endpoint: "/collaborative-playlists/songs/apple-music", model: [UpdateSongsResponse].self, parameters: parameters)
        return try await apiService.makeGetRequest(endpoint: "/collaborative-playlists/songs/apple-music", model: [UpdateSongsResponse].self)
    }
    
    private func updatePlaylistId(playlistId: String, appleMusicPlaylistId: String) async throws {
        do {
            let body = UpdateAppleMusicPlaylistIdRequest(playlistId: playlistId, appleMusicPlaylistId: appleMusicPlaylistId)
            let response = try await apiService.makePostRequest(endpoint: "/collaborative-playlists/metadata/apple-music-id", model: UpdateAppleMusicPlaylistIdResponse.self, body: body)
            if (response.appleMusicPlaylistId != appleMusicPlaylistId) {
                throw CollaborativePlaylistServiceError.playlistUpdateFailed("For backend playlist id: \(playlistId)", nil)
            }
        } catch {
            print("Failed to update playlist id for backend playlist id: \(playlistId)")
            throw error
        }
    }
    
    private func getLastUpdatedTimestamp() -> String {
        return UserDefaults.standard.object(forKey: "lastUpdatedTimestamp") as? String ?? ""
    }
    
    private func updateLastUpdatedTimestamp() {
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        UserDefaults.standard.set(formatter.string(from: currentDate), forKey: "lastUpdatedTimestamp")
    }
}
