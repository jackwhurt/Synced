class SongService {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func searchSpotifyApi(query: String, page: Int) async throws -> [SongMetadata] {
        do {
            let response = try await apiService.makeGetRequest(endpoint: "/songs/spotify?searchQuery=\(query)&page=\(page)", model: Paginated<SongMetadata>.self)
            return response.items
        } catch {
            print("Failed to search spotify api: \(error)")
            throw SongServiceError.spotifySearchFailed
        }
    }
    
    func convertSongs(spotifySongs: [SongMetadata]) async throws -> [SongMetadata] {
        do {
            let response = try await apiService.makePostRequest(endpoint: "/songs/spotify/convert", model: [SongMetadata].self, body: spotifySongs)
            return response
        } catch {
            print("Error converting Spotify songs to Apple Music: \(error)")
            throw SongServiceError.songConversionFailed
        }
    }
}
