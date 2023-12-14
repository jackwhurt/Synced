import Foundation

class CollaborativePlaylistService {
    private let apiService: APIService
    private let musicKitService: MusicKitService
    
    init(apiService: APIService, musicKitService: MusicKitService) {
        self.apiService = apiService
        self.musicKitService = musicKitService
    }
    
    func updatePlaylists() async {
        do {
            let updates = try await withCheckedThrowingContinuation { continuation in
                getSongUpdates(lastUpdatedTimeStamp: getLastUpdatedTimeStamp()) { result in
                    switch result {
                    case .success(let updates):
                        continuation.resume(returning: updates)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            for update in updates {
                await self.musicKitService.editPlaylist(songs: update.songs, to: update.playlist)
            }

            updateLastUpdatedTimeStamp()
        } catch {
            print("Error updating playlists: \(error)")
        }
    }

    private func getSongUpdates(lastUpdatedTimeStamp: Date?, completion: @escaping (Result<[UpdateSongsResponse], Error>) -> Void) {
        apiService.makeGetRequest(endpoint: "/collaborative-playlists/songs/apple-music", model: [UpdateSongsResponse].self) { result in
            switch result {
            case .failure(let error):
                print("Failed to retrieve song updates")
                completion(.failure(error))
            case .success(let songs):
                completion(.success(songs))
            }
        }
    }
    
    private func getLastUpdatedTimeStamp() -> Date? {
        return UserDefaults.standard.object(forKey: "lastUpdatedTimeStamp") as? Date
    }
    
    private func updateLastUpdatedTimeStamp() {
        UserDefaults.standard.set(Date(), forKey: "lastUpdatedTimeStamp")
    }
}
