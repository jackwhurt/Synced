import Foundation
import MusicKit

class MusicKitService {
    func createPlaylist(withTitle title: String, description: String, authorDisplayName: String?) async throws -> Playlist {
        do {
            let newPlaylist = try await MusicLibrary.shared.createPlaylist(name: title, description: description, authorDisplayName: authorDisplayName)
            return newPlaylist
        } catch {
            print("Error creating playlist \(title): \(error)")
            throw MusicKitError.failedToCreatePlaylist
        }
    }
    
    func editPlaylist(songs: any Sequence<Song>, to playlist: Playlist) async throws {
        do {
            let _ = try await MusicLibrary.shared.edit(playlist, items: songs)
        } catch {
            print("Error editing playlist \(playlist.name): \(error)")
            throw MusicKitError.failedToEditPlaylist
        }
    }
    
    func getPlaylist(id: String) async throws -> Playlist {
        var response: MusicLibraryResponse<Playlist>
        var request = MusicLibraryRequest<Playlist>()
        request.filter(matching: \.id, equalTo: MusicItemID("id"))
        
        do {
            response = try await request.response()
        } catch {
            print("Error retrieving playlist \(id): \(error)")
            throw MusicKitError.failedToRetrievePlaylist
        }

        if let playlist = response.items.first {
            return playlist
        } else {
            throw MusicKitError.playlistNotInLibrary
        }
    }
}
