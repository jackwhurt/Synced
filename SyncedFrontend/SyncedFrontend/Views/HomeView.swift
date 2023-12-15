import SwiftUI

struct HomeView: View {
    @StateObject private var cpViewModel: HomeViewModel
    
    init(isLoggedIn: Binding<Bool>) {
        _cpViewModel = StateObject(wrappedValue: HomeViewModel(
            authenticationService: DIContainer.shared.provideAuthenticationService(),
            appleMusicService: DIContainer.shared.provideAppleMusicService(),
            musicKitService: DIContainer.shared.provideMusicKitService()
            )
        )
    }
    
    var body: some View {
        VStack {
            if cpViewModel.isLoggedIn {
                Text("Logged in. Hello, World!")
                Button("Logout") {
                    cpViewModel.logout()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
                Button("Connect Apple Music") {
                    Task {
                        await cpViewModel.connectAppleMusic()
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
                
                Button("Create Playlist") {
                    Task {
                        await cpViewModel.createPlaylist()
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
            } else {
                Text("Not logged in.")
            }
        }
    }
}

// For preview
struct CollaborativePlaylistsView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(isLoggedIn: .constant(false))
    }
}
