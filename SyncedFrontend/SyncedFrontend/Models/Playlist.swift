struct PlaylistMetadata: Codable {
    let description: String?
    let title: String
}

struct CollaborativePlaylist: Codable {
    let title: String
    let description: String?
    let songs: [SongMetadata]
}
