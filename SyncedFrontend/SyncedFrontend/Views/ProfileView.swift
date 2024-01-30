import SwiftUI
import SafariServices

struct ProfileView: View {
    @State private var showingSafariView = false
    @State private var spotifyAuthURL: URL?
    @StateObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject var appSettings: AppSettings
    
    init(isLoggedIn: Binding<Bool>) {
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(
            isLoggedIn: isLoggedIn,
            appleMusicService: DIContainer.shared.provideAppleMusicService(),
            spotifyService: DIContainer.shared.provideSpotifyService(),
            authenticationService: DIContainer.shared.provideAuthenticationService())
        )
    }

    var body: some View {
        VStack {
            appleMusicConnectButton
            spotifyConnectButton
            logoutButton
        }
        .padding()
        .navigationTitle("Profile")
        .sheet(isPresented: $showingSafariView) {
            if let url = spotifyAuthURL {
                SafariView(url: url)
            }
        }
        .onChange(of: appSettings.isSpotifyConnected) { _, newValue in
            if newValue {
                showingSafariView = false
                spotifyAuthURL = nil
            }
        }
    }

    private var appleMusicConnectButton: some View {
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
    }

    private var spotifyConnectButton: some View {
        HStack {
            Text("Spotify")
                .font(.headline)
            Spacer()
            Button(action: {
                Task {
                    let url = await profileViewModel.getSpotifyAuthURL()
                    if url != nil {
                        spotifyAuthURL = url
                    }
                }
                showingSafariView = true
            }) {
                Text(appSettings.isSpotifyConnected ? "Connected" : "Connect")
                    .foregroundColor(appSettings.isSpotifyConnected ? .green : .blue)
            }
            .disabled(appSettings.isSpotifyConnected)
        }
        .padding()
    }
    
    private var logoutButton: some View {
        HStack {
            if profileViewModel.isLoggedIn {
                Text("Logged in. Hello, World!")
                Button("Logout") {
                    profileViewModel.logout()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
            } else {
                Text("Not logged in.")
            }
        }
        .padding()
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> some UIViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(isLoggedIn: .constant(true)).environmentObject(AppSettings(appleMusicService: DIContainer.shared.provideAppleMusicService()))
    }
}
