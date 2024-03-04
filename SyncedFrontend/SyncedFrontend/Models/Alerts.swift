enum SignUpAlertType: Identifiable {
    case error
    case success

    var id: Self { self }
}

enum CollaborativePlaylistAlertType: Identifiable {
    case error
    case deleteConfirmation

    var id: Self { self }
}
