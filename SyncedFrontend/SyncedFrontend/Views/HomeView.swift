import SwiftUI

struct HomeView: View {
    @StateObject private var homeViewModel: HomeViewModel
    @Binding var isLoggedIn: Bool
    
    init(isLoggedIn: Binding<Bool>) {
        _isLoggedIn = isLoggedIn
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(isLoggedIn: isLoggedIn))
    }
    
    var body: some View {
        TabView {
            CollaborativePlaylistMenuView()
                .tabItem {
                    Label("", systemImage: "music.note.list")
                }
            
            ActivityView()
                .tabItem {
                    Label("", systemImage: "person.3")
                }
            
            ProfileView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Label("", systemImage: "person")
                }
        }.accentColor(Color("SyncedBlue"))
    }
}

struct PlaceholderView: View {
    var body: some View {
        Text("Placeholder View")
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(isLoggedIn: .constant(true))
    }
}
