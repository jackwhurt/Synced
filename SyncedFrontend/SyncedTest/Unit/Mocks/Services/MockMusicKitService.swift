import Foundation
import MusicKit

class MockMusicKitService: MusicKitServiceProtocol {
    var createPlaylistCallCount = 0
    var lastCreatePlaylistParams: (title: String, description: String)?
    
    var editPlaylistCallCount = 0
    var lastEditPlaylistParams: (songs: Any, playlist: Playlist)?
    
    var softDeletePlaylistCallCount = 0
    var lastSoftDeletePlaylist: Playlist?
    
    var getPlaylistCallCount = 0
    var lastGetPlaylistId: String?
    
    var editPlaylistMetadataCallCount = 0
    var lastEditPlaylistMetadataParams: (playlist: Playlist, title: String?, description: String?, authorDisplayName: String?)?

    var createPlaylistHandler: ((String, String) async throws -> Playlist)?
    var editPlaylistHandler: ((any Sequence<Song>, Playlist) async throws -> Void)?
    var softDeletePlaylistHandler: ((Playlist) async throws -> Void)?
    var getPlaylistHandler: ((String) async throws -> Playlist)?
    var editPlaylistMetadataHandler: ((Playlist, String?, String?, String?) async throws -> Void)?

    func createPlaylist(title: String, description: String) async throws -> Playlist {
        createPlaylistCallCount += 1
        lastCreatePlaylistParams = (title, description)
        guard let handler = createPlaylistHandler else {
            fatalError("Handler not set for createPlaylist.")
        }
        return try await handler(title, description)
    }

    func editPlaylist(songs: any Sequence<Song>, to playlist: Playlist) async throws {
        editPlaylistCallCount += 1
        lastEditPlaylistParams = (songs: songs, playlist: playlist)
        guard let handler = editPlaylistHandler else {
            return
        }
        return try await handler(songs, playlist)
    }

    func softDeletePlaylist(playlist: Playlist) async throws {
        softDeletePlaylistCallCount += 1
        lastSoftDeletePlaylist = playlist
        guard let handler = softDeletePlaylistHandler else {
            return
        }
        return try await handler(playlist)
    }
    
    func editPlaylistMetadata(playlist: Playlist, title: String?, description: String?, authorDisplayName: String?) async throws {
        editPlaylistMetadataCallCount += 1
        lastEditPlaylistMetadataParams = (playlist: playlist, title: title, description: description, authorDisplayName: authorDisplayName)
        guard let handler = editPlaylistMetadataHandler else {
            return
        }
        return try await handler(playlist, title, description, authorDisplayName)
    }

    func getPlaylist(id: String) async throws -> Playlist {
        getPlaylistCallCount += 1
        lastGetPlaylistId = id
        guard let handler = getPlaylistHandler else {
            return try await getPlaylistMusicKit(id: "p.xdzZCkB3dG2")
        }
        return try await handler(id)
    }
    
    private func getPlaylistMusicKit(id: String) async throws -> Playlist {
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
}

