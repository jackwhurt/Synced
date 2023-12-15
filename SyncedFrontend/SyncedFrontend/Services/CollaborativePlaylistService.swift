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
                try await self.musicKitService.editPlaylist(songs: update.songs, to: update.playlist)
            } catch {
                print("Failed to update playlist: \(update.playlist.id.rawValue)")
                allUpdatesSuccessful = false
                throw CollaborativePlaylistServiceError.playlistUpdateFailed(update.playlist.id.rawValue, error)
            }
        }
        
        if allUpdatesSuccessful {
            updateLastUpdatedTimestamp()
        }
    }
    
//    private func decodeSongs {
        //            let mySong = "{\"id\":\"1482041830\",\"type\":\"songs\",\"attributes\":{\"url\":\"https://music.apple.com/us/album/cloud-9/1482041821?i=1482041830\"}}"
        //            guard let jsonData = mySong.data(using: .utf8) else {
        //                print("Error: Cannot create Data from jsonString")
        //                return
        //            }
        //            let decoder = JSONDecoder()
        //            let song = try decoder.decode(Song.self, from: jsonData)
//                      return song
//    }
    
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
