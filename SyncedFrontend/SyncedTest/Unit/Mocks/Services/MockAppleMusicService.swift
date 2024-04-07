import Foundation
import StoreKit
import MusicKit

class MockAppleMusicService: AppleMusicServiceProtocol {
    var fetchUserTokenCallCount = 0
    
    var requestAuthorizationCallCount = 0
    
    var checkCurrentAuthorizationStatusCallCount = 0
    
    var editPlaylistCallCount = 0
    var lastEditPlaylistParams: (appleMusicPlaylistId: String, playlistId: String, songs: [SongMetadata])?
    
    var createAppleMusicPlaylistCallCount = 0
    var lastCreateAppleMusicPlaylistParams: (title: String, description: String, playlistId: String)?
    
    var getAppleMusicPlaylistOrReplaceCallCount = 0
    var lastGetAppleMusicPlaylistOrReplaceParams: (appleMusicPlaylistId: String, playlistId: String)?

    var fetchUserTokenHandler: (() async throws -> String)?
    var requestAuthorizationHandler: (() async -> SKCloudServiceAuthorizationStatus)?
    var checkCurrentAuthorizationStatusHandler: (() -> Bool)?
    var editPlaylistHandler: ((String, String, [SongMetadata]) async throws -> Void)?
    var createAppleMusicPlaylistHandler: ((String, String, String) async throws -> Playlist)?
    var getAppleMusicPlaylistOrReplaceHandler: ((String, String) async throws -> Playlist)?

    func fetchUserToken() async throws -> String {
        fetchUserTokenCallCount += 1
        guard let handler = fetchUserTokenHandler else {
            fatalError("Handler not set for fetchUserToken.")
        }
        return try await handler()
    }

    func requestAuthorization() async -> SKCloudServiceAuthorizationStatus {
        requestAuthorizationCallCount += 1
        guard let handler = requestAuthorizationHandler else {
            fatalError("Handler not set for requestAuthorization.")
        }
        return await handler()
    }

    func checkCurrentAuthorizationStatus() -> Bool {
        checkCurrentAuthorizationStatusCallCount += 1
        guard let handler = checkCurrentAuthorizationStatusHandler else {
            fatalError("Handler not set for checkCurrentAuthorizationStatus.")
        }
        return handler()
    }

    func editPlaylist(appleMusicPlaylistId: String, playlistId: String, songs: [SongMetadata]) async throws {
        editPlaylistCallCount += 1
        lastEditPlaylistParams = (appleMusicPlaylistId, playlistId, songs)
        guard let handler = editPlaylistHandler else {
            return
        }
        return try await handler(appleMusicPlaylistId, playlistId, songs)
    }

    func createAppleMusicPlaylist(title: String, description: String, playlistId: String) async throws -> Playlist {
        createAppleMusicPlaylistCallCount += 1
        lastCreateAppleMusicPlaylistParams = (title, description, playlistId)
        guard let handler = createAppleMusicPlaylistHandler else {
            return try await getPlaylist(id: "p.xdzZCkB3dG2")
        }
        return try await handler(title, description, playlistId)
    }

    func getAppleMusicPlaylistOrReplace(appleMusicPlaylistId: String, playlistId: String) async throws -> Playlist {
        getAppleMusicPlaylistOrReplaceCallCount += 1
        lastGetAppleMusicPlaylistOrReplaceParams = (appleMusicPlaylistId, playlistId)
        
        guard let handler = getAppleMusicPlaylistOrReplaceHandler else {
            return try await getPlaylist(id: "p.xdzZCkB3dG2")
        }
    
        return try await handler(appleMusicPlaylistId, playlistId)
    }
    
    private func getPlaylist(id: String) async throws -> Playlist {
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
