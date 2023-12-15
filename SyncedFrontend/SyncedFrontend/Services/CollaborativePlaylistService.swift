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
    
    func createPlaylist(title: String, description: String) async throws -> Playlist {
        let playlist = try await musicKitService.createPlaylist(withTitle: title, description: description)
        
        return playlist
    }
    
    private func getPlaylistOrReplace(appleMusicPlaylistId: String, playlistId: String) async throws -> Playlist {
        do {
            let playlist = try await musicKitService.getPlaylist(id: appleMusicPlaylistId)
            return playlist
        } catch {
//            TODO: Implement updating the playlist id on the backend
//            let playlistMetadata = apiService.makeGetRequest(endpoint: "/collaborative-playlists/\(playlistId)", model: [CollaborativePlaylistMetadataResponse].self)
//            let playlist = musicKitService.createPlaylist(title: playlistMetadata.title, description: playlistMetadata.description);
//            await updatePlaylistId(appleMusicPlaylistId: playlist.id, playlistId: playlistId)

            throw error
        }
    }
    
    private func getSongUpdates(parameters: [String: String]) async throws -> [UpdateSongsResponse] {
        return try await apiService.makeGetRequest(endpoint: "/collaborative-playlists/songs/apple-music", model: [UpdateSongsResponse].self, parameters: parameters)
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
