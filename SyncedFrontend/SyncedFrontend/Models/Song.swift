struct SongMetadata: Codable, Hashable {
    let songId: String?
    let title: String
    let album: String
    let artist: String
    let spotifyUri: String?
    let appleMusicUrl: String?
    let appleMusicId: String?
    let coverImageUrl: String?
}
