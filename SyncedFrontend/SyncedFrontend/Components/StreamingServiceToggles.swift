import SwiftUI

struct StreamingServiceToggles: View {
    @EnvironmentObject var appSettings: AppSettings
    @Binding var isOnAppleMusic: Bool
    @Binding var isOnSpotify: Bool
    
    var body: some View {
        Toggle("Spotify Playlist", isOn: $isOnSpotify)
            .disabled(!appSettings.isSpotifyConnected)
        
        Toggle("Apple Music Playlist", isOn: $isOnAppleMusic)
            .disabled(!appSettings.isAppleMusicConnected)
        
        if !appSettings.isSpotifyConnected || !appSettings.isAppleMusicConnected {
            Text(getWarningMessage(spotify: appSettings.isSpotifyConnected, appleMusic: appSettings.isAppleMusicConnected))
                .foregroundColor(.red)
                .font(.caption)
        }
    }
    
    private func getWarningMessage(spotify: Bool, appleMusic: Bool) -> String {
        switch (spotify, appleMusic) {
        case (false, false):
            return "Neither Spotify nor Apple Music is connected."
        case (false, true):
            return "Spotify is not connected."
        case (true, false):
            return "Apple Music is not connected."
        default:
            return ""
        }
    }
}
