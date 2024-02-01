struct PlaylistMetadata: Codable {
    let title: String
    let description: String?
    let coverImageUrl: String?
    let createdBy: String?
}

struct CollaborativePlaylist: Codable {
    let title: String
    let description: String?
    let songs: [SongMetadata]
}
