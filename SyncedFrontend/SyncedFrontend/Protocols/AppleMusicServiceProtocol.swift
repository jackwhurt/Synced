import Foundation
import StoreKit
import MusicKit

protocol AppleMusicServiceProtocol {
    func fetchUserToken() async throws -> String
    func requestAuthorization() async -> SKCloudServiceAuthorizationStatus
    func checkCurrentAuthorizationStatus() -> Bool
    func editPlaylist(appleMusicPlaylistId: String, playlistId: String, songs: [SongMetadata]) async throws
    func createAppleMusicPlaylist(title: String, description: String, playlistId: String) async throws -> Playlist
    func getAppleMusicPlaylistOrReplace(appleMusicPlaylistId: String, playlistId: String) async throws -> Playlist
}
