struct UpdateAppleMusicPlaylistIdRequest: Codable {
    let playlistId: String
    let appleMusicPlaylistId: String
}

struct CreateCollaborativePlaylistRequest: Codable {
    let playlist: CollaborativePlaylist
    let collaborators: [String]
    let spotifyPlaylist: Bool
    let appleMusicPlaylist: Bool
}
