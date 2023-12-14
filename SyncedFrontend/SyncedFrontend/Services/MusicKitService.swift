import Foundation
import MusicKit

// TODO: Error handling
class MusicKitService {
    func createPlaylist(withTitle title: String, description: String, authorDisplayName: String?) async throws -> Playlist {
        do {
            let newPlaylist = try await MusicLibrary.shared.createPlaylist(name: title, description: description, authorDisplayName: authorDisplayName)
            return newPlaylist
        } catch {
            // Handle or throw the error
            throw error
        }
    }
    
    func editPlaylist(songs: any Sequence<Song>, to playlist: Playlist) async {
        do {
            let _ = try await MusicLibrary.shared.edit(playlist, items: songs)
        } catch {
            print("Error adding songs to the playlist \(playlist.name): \(error)")
        }
    }
}
