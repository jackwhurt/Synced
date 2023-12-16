import MusicKit

struct DeveloperTokenResponse: Codable {
    let appleMusicToken: String
}

struct UpdateSongsResponse: Codable {
    let playlistId: String
    let appleMusicPlaylistId: String
    let songs: [Song]
}

struct CollaborativePlaylistMetadataResponse: Codable {
    let playlistId: String
    let metadata: PlaylistMetadata
}

struct PlaylistMetadata: Codable {
    let description: String?
    let title: String
}

// TODO: Remove
//struct UpdateSongsResponse: Codable {
//    let id: String
//    let type: String
//    let attributes: Attributes
//}
//
//struct Attributes: Codable {
//    let url: String
//}
