import MusicKit

struct DeveloperTokenResponse: Codable {
    let appleMusicToken: String
}

struct UpdateSongsResponse: Codable {
    let playlistId: String
    let appleMusicPlaylistId: String
    let songs: [Song]
}

struct GetCollaborativePlaylistResponse: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let coverImageUrl: String?
}

struct GetCollaborativePlaylistByIdResponse: Codable {
    let playlistId: String
    let metadata: PlaylistMetadata
    let songs: [SongMetadata]
}

struct GetCollaborativePlaylistMetadataResponse: Codable {
    let playlistId: String
    let metadata: PlaylistMetadata
}

struct UpdateAppleMusicPlaylistIdResponse: Codable {
    let appleMusicPlaylistId: String
}

struct CreateCollaborativePlaylistResponse: Codable {
    let id: String
}

