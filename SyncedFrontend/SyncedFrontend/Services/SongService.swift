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
}
