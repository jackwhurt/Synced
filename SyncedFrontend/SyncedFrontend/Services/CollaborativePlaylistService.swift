import Foundation

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
                // TODO: Change updatesongsresponse to have db playlist id and implement logic so can update the apple music playlist id if needs to be recreated
                let playlist = try await musicKitService.getPlaylist(id: update.playlistId)
                try await self.musicKitService.editPlaylist(songs: update.songs, to: playlist)
            } catch {
                print("Failed to update playlist \(update.playlistId): \(error)")
                allUpdatesSuccessful = false
                throw CollaborativePlaylistServiceError.playlistUpdateFailed(update.playlistId, error)
            }
        }
        
        if allUpdatesSuccessful {
            updateLastUpdatedTimestamp()
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
