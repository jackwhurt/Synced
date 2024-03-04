struct PlaylistRequest: Codable, Hashable {
    let playlistId: String
    let playlistTitle: String
    let playlistDescription: String
    let userId: String
    let requestId: String
    let createdBy: String
    let createdByUsername: String
    let createdAt: String
    var isDeclining: Bool? = false
}

struct UserRequest: Codable, Hashable {
    let userId: String
    let requestId: String
    let createdBy: String
    let createdByUsername: String
    let createdAt: String
}

struct Requests: Codable {
    let playlistRequests: [PlaylistRequest]
    let userRequests: [UserRequest]
}
