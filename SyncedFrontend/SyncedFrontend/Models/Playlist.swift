struct PlaylistMetadata: Codable {
    let title: String
    let description: String?
    let createdBy: String?
    let coverImageUrl: String?
}

struct CollaborativePlaylist: Codable {
    let title: String
    let description: String?
    let songs: [SongMetadata]
}
