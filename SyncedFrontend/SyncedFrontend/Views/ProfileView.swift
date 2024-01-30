import SwiftUI
import SafariServices

struct ProfileView: View {
    @State private var showingSafariView = false
    @State private var spotifyAuthURL: URL?
    @StateObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject var appSettings: AppSettings

    init() {
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(
            appleMusicService: DIContainer.shared.provideAppleMusicService(), spotifyService: DIContainer.shared.provideSpotifyService())
        )
    }

    var body: some View {
        VStack {
            HStack {
                Text("Apple Music")
                    .font(.headline)
                Spacer()
                Button(action: {
                    if !appSettings.isAppleMusicConnected {
                        Task {
                            appSettings.isAppleMusicConnected = await profileViewModel.requestAuthentication()
                        }
                    }
                }) {
                    Text(appSettings.isAppleMusicConnected ? "Connected" : "Connect")
                        .foregroundColor(appSettings.isAppleMusicConnected ? .syncedErrorRed : .blue)
                }
                .disabled(appSettings.isAppleMusicConnected)
            }
            .padding()

            HStack {
                Text("Spotify")
                    .font(.headline)
                Spacer()
                Button(action: {
                    Task {
                        let url = await profileViewModel.getSpotifyAuthURL()
                        if url != nil {
                            spotifyAuthURL = url
                            showingSafariView = true
                        }
                    }
                }) {
                    Text(appSettings.isSpotifyConnected ? "Connected" : "Connect")
                        .foregroundColor(appSettings.isSpotifyConnected ? .green : .blue)
                }
            }
            .padding()
            
        }
        .padding()
        .navigationTitle("Profile")
        .sheet(isPresented: $showingSafariView) {
            if let url = spotifyAuthURL {
                SafariView(url: url)
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> some UIViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView().environmentObject(AppSettings(appleMusicService: DIContainer.shared.provideAppleMusicService()))
    }
}
