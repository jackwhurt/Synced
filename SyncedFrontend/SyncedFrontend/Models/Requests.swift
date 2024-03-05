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

struct DeleteSongsRequest: Codable {
    let playlistId: String
    let songs: [SongMetadata]
}

struct AddSongsRequest: Codable {
    let playlistId: String
    let songs: [SongMetadata]
}

struct DeleteAppleMusicDeleteFlagsRequest: Codable {
    let playlistIds: [String]
}

struct AddCollaboratorsRequest: Codable {
    let playlistId: String
    let collaboratorIds: [String]
}

struct DeleteCollaboratorsRequest: Codable {
    let playlistId: String
    let collaboratorIds: [String]
}
