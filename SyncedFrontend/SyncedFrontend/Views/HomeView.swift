import SwiftUI

struct HomeView: View {
    @StateObject private var homeViewModel: HomeViewModel
    
    init(isLoggedIn: Binding<Bool>) {
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(isLoggedIn: isLoggedIn))
    }
    
    var body: some View {
        TabView {
            CollaborativePlaylistView()
                .tabItem {
                    Label("", systemImage: "music.note.list")
                }

            // TODO: Remove
            TestView(isLoggedIn: .constant(true))
                .tabItem {
                    Label("", systemImage: "ellipsis.circle.fill")
                }
            
            ActivitiesView()
                .tabItem {
                    Label("", systemImage: "person.3")
                }
            
            ProfileView()
                .tabItem {
                    Label("", systemImage: "person")
                }
        }.accentColor(Color("SyncedBlue"))
    }
}

struct ProfileView: View {
    var body: some View {
        Text("Profile View")
    }
}

struct ActivitiesView: View {
    var body: some View {
        Text("Activities View")
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
