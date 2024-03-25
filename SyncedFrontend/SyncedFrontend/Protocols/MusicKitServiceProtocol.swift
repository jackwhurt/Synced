import Foundation
import MusicKit

protocol MusicKitServiceProtocol {
    func createPlaylist(title: String, description: String) async throws -> Playlist
    func editPlaylist(songs: any Sequence<Song>, to playlist: Playlist) async throws
    func softDeletePlaylist(playlist: Playlist) async throws
    func getPlaylist(id: String) async throws -> Playlist
    func editPlaylistMetadata(playlist: Playlist, title: String?, description: String?, authorDisplayName: String?) async throws
}
