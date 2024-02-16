import Foundation
import MusicKit

// TODO: unauthorised playlist issue, i.e. user has redownloaded the app
class CollaborativePlaylistService {
    private let apiService: APIService
    private let appleMusicService: AppleMusicService
    private let musicKitService: MusicKitService
    
    init(apiService: APIService, appleMusicService: AppleMusicService, musicKitService: MusicKitService) {
        self.apiService = apiService
        self.appleMusicService = appleMusicService
        self.musicKitService = musicKitService
    }
    
    func getPlaylists() async throws -> [GetCollaborativePlaylistResponse] {
        do {
            let response = try await apiService.makeGetRequest(endpoint: "/collaborative-playlists", model: [GetCollaborativePlaylistResponse].self)
            CachingService.shared.save(response, forKey: "collaborativePlaylists")
            return response
        } catch {
            print("Failed to retrieve collaborative playlists")
            throw CollaborativePlaylistServiceError.playlistRetrievalFailed
        }
    }
    
    func getPlaylistById(playlistId: String) async throws -> GetCollaborativePlaylistByIdResponse {
        do {
            let response = try await apiService.makeGetRequest(endpoint: "/collaborative-playlists/\(playlistId)", model: GetCollaborativePlaylistByIdResponse.self)
            CachingService.shared.save(response.metadata, forKey: "playlistMetadata_\(playlistId)")
            CachingService.shared.save(response.songs, forKey: "playlistSongs_\(playlistId)")
            return response
        } catch {
            print("Failed to retrieve collaborative playlist")
            throw CollaborativePlaylistServiceError.playlistRetrievalFailed
        }
    }
    
    func createPlaylist(request: CreateCollaborativePlaylistRequest) async throws -> String {
        do {
            let backendPlaylistId = try await createBackendPlaylist(request: request)
            print("Successfully created backend playlist, id: \(backendPlaylistId)")
            
            var appleMusicPlaylist: Playlist
            if request.appleMusicPlaylist {
                appleMusicPlaylist = try await appleMusicService.createAppleMusicPlaylist(title: request.playlist.title, description: request.playlist.description ?? "", playlistId: backendPlaylistId)
                print("Successfully created Apple Music playlist, id: \(appleMusicPlaylist.id.rawValue)")
            }

            return backendPlaylistId
        } catch {
            print("Failed to create playlist \(request.playlist.title)")
            throw CollaborativePlaylistServiceError.playlistCreationFailed
        }
    }
    
    func deletePlaylist(playlistId: String, appleMusicPlaylistId: String?) async throws -> String {
        do {
            if let id = appleMusicPlaylistId {
                let playlist = try await musicKitService.getPlaylist(id: id)
                try await self.musicKitService.softDeletePlaylist(playlist: playlist)
                print("Successfully soft deleted apple music playlist, id: \(id)")
            }
            let deletedPlaylistId = try await deleteBackendPlaylist(playlistId: playlistId)
            print("Successfully deleted backend playlist, id: \(deletedPlaylistId)")
            return deletedPlaylistId
        } catch {
            print("Failed to delete playlist \(playlistId)")
            throw CollaborativePlaylistServiceError.playlistDeletionFailed
        }
    }
    
    func editSongs(appleMusicPlaylistId: String?, playlistId: String, songsToDelete: [SongMetadata], songsToAdd: [SongMetadata], oldSongs: [SongMetadata]) async throws {
        try await addSongsToBackendIfNeeded(playlistId: playlistId, songsToAdd: songsToAdd)
        try await deleteSongsFromBackendIfNeeded(playlistId: playlistId, songsToDelete: songsToDelete)

        guard (!songsToAdd.isEmpty || !songsToDelete.isEmpty), let appleMusicPlaylistId = appleMusicPlaylistId else {
            return
        }

        let newPlaylistSongs = updatePlaylistSongs(oldSongs: oldSongs, songsToAdd: songsToAdd, songsToDelete: songsToDelete)
        try await appleMusicService.editPlaylist(appleMusicPlaylistId: appleMusicPlaylistId, playlistId: playlistId, songs: newPlaylistSongs)
        print("Successfully edited apple music playlist songs for playlist: \(playlistId)")
    }
    
    func updatePlaylists() async throws {
        let timestampDict = ["timestamp": getLastUpdatedTimestamp()]
        let currentDate = Date()

        let update = try await fetchSongUpdates(timestampDict: timestampDict)
        let allSongUpdatesSuccessful = try await processSongUpdates(update.songUpdates)
        let deleteFlagsToDelete = try await processPlaylistUpdates(update.playlistUpdates)

        if !deleteFlagsToDelete.isEmpty {
            await deleteAppleMusicDeleteFlags(playlistIds: deleteFlagsToDelete)
        }
        
        if allSongUpdatesSuccessful {
            updateLastUpdatedTimestamp(currentDate: currentDate)
            print("Updated last updated timestamp: \(currentDate)")
        }
    }
    
    func deleteAppleMusicDeleteFlags(playlistIds: [String]) async {
        do {
            _ = try await apiService.makeDeleteRequest(endpoint: "/songs/apple-music", model: DeleteAppleMusicDeleteFlagsResponse.self, body: DeleteAppleMusicDeleteFlagsRequest(playlistIds: playlistIds))
            print("Successfully deleted delete flags for playlists \(playlistIds)")
        } catch {
            print("Failed to delete delete flags for playlists \(playlistIds): \(error)")
        }
    }

    private func createBackendPlaylist(request: CreateCollaborativePlaylistRequest) async throws -> String {
        do {
            let response = try await apiService.makePostRequest(endpoint: "/collaborative-playlists", model: CreateCollaborativePlaylistResponse.self, body: request)
            guard let playlistID = response.id else {
                throw CollaborativePlaylistServiceError.backendPlaylistCreationFailed
            }
            return playlistID
        } catch {
            print("Failed to create playlist \(request.playlist.title) on the backend")
            throw CollaborativePlaylistServiceError.backendPlaylistCreationFailed
        }
    }
    
    private func deleteBackendPlaylist(playlistId: String) async throws -> String {
        do {
            let response = try await apiService.makeDeleteRequest(endpoint: "/collaborative-playlists/\(playlistId)", model: DeleteCollaborativePlaylistResponse.self, body: "")
            guard let playlistID = response.id else {
                throw CollaborativePlaylistServiceError.backendPlaylistDeletionFailed
            }
            return playlistID
        } catch {
            print("Failed to delete playlist \(playlistId) on the backend")
            throw CollaborativePlaylistServiceError.backendPlaylistDeletionFailed
        }
    }
    
    private func fetchSongUpdates(timestampDict: [String: String]) async throws -> UpdatePlaylistsResponse {
        do {
            return try await getSongUpdates(parameters: timestampDict)
        } catch {
            print("Failed to retrieve song updates for timestamp: ", timestampDict["timestamp"] ?? "Unknown")
            throw AppleMusicServiceError.songUpdatesRetrievalFailed
        }
    }
    
    private func addSongsToBackendIfNeeded(playlistId: String, songsToAdd: [SongMetadata]) async throws {
        guard !songsToAdd.isEmpty else { return }

        let response = try await apiService.makePostRequest(endpoint: "/collaborative-playlists/songs", model: AddSongsResponse.self, body: AddSongsRequest(playlistId: playlistId, songs: songsToAdd))
        guard response.error == nil else {
            print("Failed to add songs on the backend")
            throw CollaborativePlaylistServiceError.failedToAddSongs
        }

        print("Successfully added songs to backend for playlist: \(playlistId)")
    }

    private func deleteSongsFromBackendIfNeeded(playlistId: String, songsToDelete: [SongMetadata]) async throws {
        guard !songsToDelete.isEmpty else { return }

        let response = try await apiService.makeDeleteRequest(endpoint: "/collaborative-playlists/songs", model: DeleteSongsResponse.self, body: DeleteSongsRequest(playlistId: playlistId, songs: songsToDelete))
        guard response.error == nil else {
            print("Failed to delete songs on the backend")
            throw CollaborativePlaylistServiceError.failedToDeleteSongs
        }

        print("Successfully deleted songs from backend playlist: \(playlistId)")
    }

    private func updatePlaylistSongs(oldSongs: [SongMetadata], songsToAdd: [SongMetadata], songsToDelete: [SongMetadata]) -> [SongMetadata] {
        let addedSongs = oldSongs + songsToAdd
        return addedSongs.filter { !songsToDelete.contains($0) }
    }

    private func processSongUpdates(_ songUpdates: [SongUpdate]) async throws -> Bool {
        var allUpdatesSuccessful = true
        for songUpdate in songUpdates {
            do {
                let playlist = try await appleMusicService.getAppleMusicPlaylistOrReplace(appleMusicPlaylistId: songUpdate.appleMusicPlaylistId, playlistId: songUpdate.playlistId)
                try await self.musicKitService.editPlaylist(songs: songUpdate.songs, to: playlist)
            } catch {
                allUpdatesSuccessful = false
                print("Failed to update playlist songs for backend id: \(songUpdate.playlistId): \(error)")
                throw AppleMusicServiceError.songUpdateFailed
            }
        }
        return allUpdatesSuccessful
    }

    private func processPlaylistUpdates(_ playlistUpdates: [PlaylistUpdate]) async throws -> [String] {
        var deleteFlagsToDelete: [String] = []
        for playlistUpdate in playlistUpdates {
            do {
                if playlistUpdate.delete ?? false {
                    let playlist = try await musicKitService.getPlaylist(id: playlistUpdate.appleMusicPlaylistId)
                    try await self.musicKitService.softDeletePlaylist(playlist: playlist)
                    deleteFlagsToDelete.append(playlistUpdate.playlistId)
                }
            } catch {
                if case MusicKitError.playlistNotInLibrary = error {
                    deleteFlagsToDelete.append(playlistUpdate.playlistId)
                } else {
                    print("Failed to update playlist for apple music id: \(playlistUpdate.appleMusicPlaylistId): \(error)")
                    throw AppleMusicServiceError.playlistUpdateFailed
                }
            }
        }
        return deleteFlagsToDelete
    }

    private func getSongUpdates(parameters: [String: String]) async throws -> UpdatePlaylistsResponse {
        return try await apiService.makeGetRequest(endpoint: "/songs/apple-music", model: UpdatePlaylistsResponse.self, parameters: parameters)
    }
    
    private func getLastUpdatedTimestamp() -> String {
        return UserDefaults.standard.object(forKey: "lastUpdatedTimestamp") as? String ?? ""
    }
    
    private func updateLastUpdatedTimestamp(currentDate: Date) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        
        UserDefaults.standard.set(formatter.string(from: currentDate), forKey: "lastUpdatedTimestamp")
    }
}
