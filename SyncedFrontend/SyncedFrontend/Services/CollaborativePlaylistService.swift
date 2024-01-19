import Foundation
import MusicKit

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
            return response
        } catch {
            print("Failed to retrieve collaborative playlists")
            throw CollaborativePlaylistServiceError.playlistRetrievalFailed
        }
    }
    
    func getPlaylistById(playlistId: String) async throws -> GetCollaborativePlaylistByIdResponse {
        do {
            let response = try await apiService.makeGetRequest(endpoint: "/collaborative-playlists/\(playlistId)", model: GetCollaborativePlaylistByIdResponse.self)
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
    
    func deletePlaylist(playlistId: String) async throws -> String {
        do {
            let deletedPlaylistId = try await deleteBackendPlaylist(playlistId: playlistId)
            print("Successfully deleted backend playlist, id: \(deletedPlaylistId)")
            return deletedPlaylistId
        } catch {
            print("Failed to delete playlist \(playlistId)")
            throw CollaborativePlaylistServiceError.playlistDeletionFailed
        }
    }
    
    func editSongs(appleMusicPlaylistId: String?, playlistId: String, songsToDelete: [SongMetadata], songsToAdd: [SongMetadata], newSongs: [SongMetadata]) async throws {
        do {
            if !songsToAdd.isEmpty {
                _ = try await apiService.makePostRequest(endpoint: "/collaborative-playlists/songs", model: AddSongsResponse.self, body: AddSongsRequest(playlistId: playlistId, songs: songsToAdd))
                print("Successfully added songs to backend")
            }
            if !songsToDelete.isEmpty {
                _ = try await apiService.makeDeleteRequest(endpoint: "/collaborative-playlists/songs", model: DeleteSongsResponse.self, body: DeleteSongsRequest(playlistId: playlistId, songs: songsToDelete))
                print("Successfully deleted songs from backend")
            }
            if !songsToAdd.isEmpty || !songsToDelete.isEmpty, let appleMusicPlaylistId = appleMusicPlaylistId {
                try await appleMusicService.editPlaylist(appleMusicPlaylistId: appleMusicPlaylistId, playlistId: playlistId, songs: newSongs)
                print("Successfully edited apple music playlist songs")
            }
        } catch {
            print("Failed to edit songs")
            throw CollaborativePlaylistServiceError.failedToEditSongs
        }
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
                print("Failed to update playlist for apple music id: \(playlistUpdate.appleMusicPlaylistId): \(error)")
                throw AppleMusicServiceError.playlistUpdateFailed
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
