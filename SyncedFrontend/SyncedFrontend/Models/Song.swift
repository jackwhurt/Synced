struct SongMetadata: Codable, Hashable, Equatable {
    let songId: String?
    let title: String
    let album: String?
    let artist: String?
    let spotifyUri: String?
    let appleMusicUrl: String?
    let appleMusicId: String?
    let coverImageUrl: String?
}

struct SongMetadataAppleMusic: Codable {
    let id: String
    let type: String
    let attributes: Attributes
}

struct Attributes: Codable {
    let url: String
}
