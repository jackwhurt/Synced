import Foundation
import SwiftUI

class AddSongsViewModel: ObservableObject {
    @Published var spotifySongs: [SongMetadata] = []
    @Published var selectedSongs: Set<SongMetadata>
    @Published var errorMessage: String?
    @Binding var songsToAdd: [SongMetadata]
    var dismissAction: () -> Void = {}
    let playlistSongs: Set<String>
    
    private let songService: SongService
    
    init(songService: SongService, playlistSongs: [SongMetadata], songsToAdd: Binding<[SongMetadata]>) {
        self.songService = songService
        self._songsToAdd = songsToAdd
        self.selectedSongs = Set<SongMetadata>()
        self.playlistSongs = Set(playlistSongs.compactMap({ $0.spotifyUri }))
    }
    
    func searchSpotifyApi(query: String, page: Int) async {
        do {
            let response = try await songService.searchSpotifyApi(query: query, page: page)
            DispatchQueue.main.async { [weak self] in
                self?.spotifySongs = response
            }
        } catch {
            print("Failed to search spotify api: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to load songs. Please try again later"
            }
        }
    }
    
    func toggleSongSelection(song: SongMetadata) {
        if playlistSongs.contains(song.spotifyUri ?? "DEFAULT") {
            return
        }
        
        if selectedSongs.contains(song) {
            self.selectedSongs.remove(song)
        } else {
            self.selectedSongs.insert(song)
        }
    }
    
    // TODO: Intermediatory step to confirm we have the correct conversions
    func convertSongs() async {
        do {
            let convertedSongs = try await songService.convertSongs(spotifySongs: Array(selectedSongs))
            print("Successfully converted songs to: \(convertedSongs)")
            DispatchQueue.main.async { [weak self] in
                self?.songsToAdd.append(contentsOf: convertedSongs)
                self?.dismissAction()
            }
        } catch {
            print("Failed saving songs to playlist: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to convert songs from Spotify to Apple Music. Please try again later"
            }
        }
    }
    
    func containsSong(song: SongMetadata) -> Bool {
        return selectedSongs.contains(song) || playlistSongs.contains(song.spotifyUri ?? "DEFAULT")
    }
}
