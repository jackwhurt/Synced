struct UserMetadata: Codable, Hashable {
    let userId: String
    let username: String
    let email: String?
    let bio: String?
    let isSpotifyConnected: Bool?
    var photoUrl: String?
}
