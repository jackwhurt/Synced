import MusicKit

struct DeveloperTokenResponse: Codable {
    let appleMusicToken: String
}

struct UpdateSongsResponse: Codable {
    let playlistId: String
    let songs: [Song]
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
