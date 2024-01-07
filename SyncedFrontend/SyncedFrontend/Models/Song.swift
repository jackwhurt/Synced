struct SongMetadata: Codable {
    let songId: String?
    let title: String
    let artist: String
    let spotifyUri: String?
    let appleMusicUrl: String?
    let appleMusicId: String?
    let coverImageUrl: String?
}
