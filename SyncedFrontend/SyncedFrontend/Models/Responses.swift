import MusicKit

struct DeveloperTokenResponse: Codable {
    let appleMusicToken: String
}

struct UpdatePlaylistsResponse: Codable {
    let songUpdates: [SongUpdate]
    let playlistUpdates: [PlaylistUpdate]
}

struct SongUpdate: Codable {
    let playlistId: String
    let appleMusicPlaylistId: String
    let songs: [Song]
}

struct PlaylistUpdate: Codable {
    let appleMusicPlaylistId: String
    let playlistId: String
    let description: String?
    let title: String?
    let delete: Bool?
}

struct GetCollaborativePlaylistResponse: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let coverImageUrl: String?
}

struct GetCollaborativePlaylistByIdResponse: Codable {
    let playlistId: String
    let appleMusicPlaylistId: String?
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
    let id: String?
}

struct DeleteCollaborativePlaylistResponse: Codable {
    let id: String?
}

struct DeleteSongsResponse: Codable {
    let message: String?
    let error: String?
}

struct AddSongsResponse: Codable {
    let message: String?
    let error: String?
}

struct DeleteAppleMusicDeleteFlagsResponse: Codable {
    let message: String
}

struct GetUsersResponse: Codable {
    let users: [UserMetadata]
    let lastEvaluatedKey: Int?
}

struct GetRequestsResponse: Codable {
    let requests: Requests?
    let lastEvaluatedKey: String?
    let error: String?
}

struct ResolveRequestResponse: Codable {
    let message: String?
    let error: String?
}

