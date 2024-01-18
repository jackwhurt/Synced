import Foundation
import MusicKit

class MusicKitService {
    func createPlaylist(title: String, description: String) async throws -> Playlist {
        do {
            let newPlaylist = try await MusicLibrary.shared.createPlaylist(name: title, description: description, authorDisplayName: "Synced")
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
    
    func softDeletePlaylist(playlist: Playlist) async throws {
        do {
            let emptySongsList: [Song] = []
            try await editPlaylist(songs: emptySongsList, to: playlist)
            try await editPlaylistMetadata(playlist: playlist, title: "Deleted Playlist", description: "", authorDisplayName: nil)
        } catch {
            print("Error performing soft delete on playlist \(playlist.name): \(error)")
            throw MusicKitError.failedToSoftDeletePlaylist
        }
    }

    func getPlaylist(id: String) async throws -> Playlist {
        var response: MusicLibraryResponse<Playlist>
        var request = MusicLibraryRequest<Playlist>()
        request.filter(matching: \.id, equalTo: MusicItemID(id))
        
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
    
    // TODO: Complete
    func editPlaylistMetadata(playlist: Playlist, title: String?, description: String?, authorDisplayName: String?) async throws {
        do {
            try await MusicLibrary.shared.edit(playlist, name: title, description: description, authorDisplayName: authorDisplayName)
        } catch {
            print("Failed to edit playlist metadata for playlist \(playlist.id): \(error)")
            throw MusicKitError.failedToEditPlaylist
        }
    }
}
