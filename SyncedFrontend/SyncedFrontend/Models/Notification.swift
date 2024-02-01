struct NotificationMetadata: Codable, Hashable {
    let message: String
    let createdBy: String
    let notificationId: String
    let playlistId: String?
    let createdAt: String?
}
