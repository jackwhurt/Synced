import Foundation
import SwiftUI

class AddSongsViewModel: ObservableObject {
    @Published var spotifySongs: [SongMetadata] = []
    @Published var selectedSongs = Set<SongMetadata>()
    @Binding var songsToAdd: [SongMetadata]
    var dismissAction: () -> Void = {}
    
    private let songService: SongService
    
    init(songService: SongService, songsToAdd: Binding<[SongMetadata]>) {
        self.songService = songService
        self._songsToAdd = songsToAdd
    }
    
    // TODO: Display error to user
    func searchSpotifyApi(query: String, page: Int) async {
        do {
            let response = try await songService.searchSpotifyApi(query: query, page: page)
            DispatchQueue.main.async { [weak self] in
                self?.spotifySongs = response
            }
        } catch {
            print("Failed to search spotify api: \(error)")
        }
    }
    
    func toggleSongSelection(song: SongMetadata) {
        if selectedSongs.contains(song) {
            self.selectedSongs.remove(song)
        } else {
            self.selectedSongs.insert(song)
        }
    }
    
    // TODO: Intermediatory step to confirm we have the correct conversions
    // TODO: Display error to user
    func convertSongs() async {
        do {
            let convertedSongs = try await songService.convertSongs(spotifySongs: Array(selectedSongs))
            print("Successfully converted songs to: \(convertedSongs)")
            DispatchQueue.main.async { [weak self] in
                self?.dismissAction()
                self?.songsToAdd.append(contentsOf: convertedSongs)
                self?.selectedSongs = Set<SongMetadata>()
            }
        } catch {
            print("Failed saving songs to playlist: \(error)")
        }
    }
}
