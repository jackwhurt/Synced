import SwiftUI
import SafariServices

struct ProfileView: View {
    @EnvironmentObject var appSettings: AppSettings
    
    @StateObject private var profileViewModel: ProfileViewModel
    @State private var spotifyAuthURL: IdentifiableURL?
    @State private var showErrorAlert = false
    
    init(isLoggedIn: Binding<Bool>) {
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(
            isLoggedIn: isLoggedIn,
            appleMusicService: DIContainer.shared.provideAppleMusicService(),
            spotifyService: DIContainer.shared.provideSpotifyService(),
            authenticationService: DIContainer.shared.provideAuthenticationService(),
            userService: DIContainer.shared.provideUserService(),
            imageService: DIContainer.shared.provideImageService())
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                if profileViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                }
                profileContent
                    .padding()
                    .sheet(item: $spotifyAuthURL) { url in
                        SafariView(idUrl: url)
                    }
                    .alert("Error", isPresented: $showErrorAlert, presenting: profileViewModel.errorMessage) { detail in
                        Button("OK") { profileViewModel.errorMessage = nil }
                    } message: { detail in
                        Text(detail)
                    }
            }
            .navigationTitle("Profile")
            .toolbar { navigationBarMenu() }
            .animation(.easeInOut(duration: 0.2), value: profileViewModel.isLoading)
            .transition(.slide)
            .onAppear(perform:{
                Task {
                    await profileViewModel.loadUser()
                }
                if let isConnected = profileViewModel.user?.isSpotifyConnected {
                    appSettings.isSpotifyConnected = isConnected
                }
            })
        }
    }
    
    private var profileContent: some View {
        VStack {
            HStack {
                ProfilePictureView(profileViewModel: profileViewModel)
                VStack {
                    ProfileDetailsView(profileViewModel: profileViewModel)
                    if profileViewModel.isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(width: 180, height: 35)
                    } else {
                        EditProfileView(profileViewModel: profileViewModel)
                    }
                }
            }
            Divider()
            VStack {
                Text("Your Streaming Services")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.top, 10)
                StreamingServiceConnectView(profileViewModel: profileViewModel, spotifyAuthURL: $spotifyAuthURL, appSettings: _appSettings)
            }
            LogoutButtonView(profileViewModel: profileViewModel)
        }
        .onChange(of: appSettings.isSpotifyConnected) { _, newValue in
            if newValue {
                spotifyAuthURL = nil
            }
        }
        .onChange(of: profileViewModel.errorMessage) {
            if profileViewModel.errorMessage != nil {
                DispatchQueue.main.async {
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func navigationBarMenu() -> some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            if profileViewModel.isEditing {
                Button("Cancel") {
                    profileViewModel.cancelChanges()
                }
            }
        }
    }
}

struct ProfilePictureView: View {
    @StateObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        ZStack {
            if let imagePreview = profileViewModel.imagePreview {
                Image(uiImage: imagePreview)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
            } else {
                ProfileAsyncImageLoader(urlString: profileViewModel.user?.photoUrl, width: 110, height: 110)
            }
            
            if profileViewModel.isEditing {
                SelectImage(onImageSelected: { selectedImage in
                    profileViewModel.imagePreview = selectedImage
                })
            }
        }
    }
}

struct ProfileDetailsView: View {
    @StateObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            if let username = profileViewModel.user?.username {
                Text("@\(username)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            if let bio = profileViewModel.user?.bio {
                Text(bio)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal)
    }
}


struct EditProfileView: View {
    @StateObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        if profileViewModel.isEditing {
            RoundButton(title: "Save Changes", action: {
                profileViewModel.saveChanges()
            }, backgroundColour: .green, width: 180, height: 35)
        } else {
            RoundButton(title: "Edit Profile", action: {
                profileViewModel.isEditing = true
            },  width: 180, height: 35)
        }
    }
}

struct StreamingServiceConnectView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var spotifyAuthURL: IdentifiableURL?
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        VStack {
            ServiceConnectButton(service: .appleMusic,
                                 logoName: "AppleMusicLogo",
                                 isConnected: appSettings.isAppleMusicConnected,
                                 action: connectAppleMusic)
            
            ServiceConnectButton(service: .spotify,
                                 logoName: "SpotifyLogo",
                                 isConnected: appSettings.isSpotifyConnected,
                                 action: connectSpotify)
        }
    }
    
    private func connectAppleMusic() {
        if !appSettings.isAppleMusicConnected {
            Task {
                appSettings.isAppleMusicConnected = await profileViewModel.requestAuthentication()
            }
        }
    }
    
    private func connectSpotify() {
        Task {
            let url = await profileViewModel.getSpotifyAuthURL()
            if let url = url {
                spotifyAuthURL = IdentifiableURL(url: url)
            }
        }
    }
}

struct ServiceConnectButton: View {
    let service: StreamingService
    let logoName: String
    let isConnected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Image(logoName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
            Button(action: action) {
                Text(isConnected ? "Connected" : "Connect")
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .frame(height: 44)
                    .background(isConnected ? Color.green : Color.syncedErrorRed)
                    .cornerRadius(22)
            }
            .disabled(isConnected)
            .padding(.horizontal)
        }
    }
}

struct LogoutButtonView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        VStack {
            Button(action: profileViewModel.logout) {
                Text("Logout")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.syncedErrorRed)
                    .cornerRadius(20)
            }
            .padding(.top, 40)
        }
        .padding()
    }
}

struct SafariView: UIViewControllerRepresentable {
    let idUrl: IdentifiableURL
    
    func makeUIViewController(context: Context) -> some UIViewController {
        SFSafariViewController(url: idUrl.url)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

enum StreamingService {
    case appleMusic, spotify
}

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(isLoggedIn: .constant(true))
    }
}
