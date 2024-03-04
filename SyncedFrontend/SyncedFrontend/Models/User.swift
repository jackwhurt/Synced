struct UserMetadata: Codable, Hashable {
    let userId: String
    let username: String
    let email: String?
    let photoUrl: String?
    let bio: String?
    let isSpotifyConnected: Bool?
    let requestStatus: String?
    let isPlaylistOwner: Bool?
}
