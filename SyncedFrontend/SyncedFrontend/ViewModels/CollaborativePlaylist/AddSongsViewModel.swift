import Foundation

class AddSongsViewModel: ObservableObject {
    private let songService: SongService
    @Published var spotifySongs: [SongMetadata] = []
    @Published var selectedSongUris = Set<String>()

    init(songService: SongService) {
        self.songService = songService
    }
    
    func searchSpotifyApi(query: String, page: Int) async {
        do {
            let response = try await songService.searchSpotifyApi(query: query, page: page)
            DispatchQueue.main.async {
                self.spotifySongs = response
            }
        } catch {
            print("Failed to search spotify api: \(error)")
        }
    }
    
    func toggleSongSelection(spotifyUri: String) {
         if selectedSongUris.contains(spotifyUri) {
             selectedSongUris.remove(spotifyUri)
         } else {
             selectedSongUris.insert(spotifyUri)
         }
     }
    
    func saveSongs() async {
        
    }
}
