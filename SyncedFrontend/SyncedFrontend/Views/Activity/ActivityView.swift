import SwiftUI

struct ActivityView: View {
    @StateObject private var activityViewModel: ActivityViewModel
    
    init() {
        _activityViewModel = StateObject(wrappedValue: ActivityViewModel(activityService: DIContainer.shared.provideActivityService()))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    if activityViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    }
                    List {
                        ViewRequestsView(activityViewModel: activityViewModel)
                        NotificationsView(activityViewModel: activityViewModel)
                    }
                    .navigationBarTitle("Activities", displayMode: .large)
                }
                .animation(.easeInOut(duration: 0.2), value: activityViewModel.isLoading)
                .transition(.slide)
                .alert("Error", isPresented: Binding<Bool>(
                    get: { self.activityViewModel.errorMessage != nil },
                    set: { _ in self.activityViewModel.errorMessage = nil }
                ), presenting: activityViewModel.errorMessage) { errorMessage in
                    Button("OK", role: .cancel) { }
                } message: { errorMessage in
                    Text(errorMessage)
                }
            }
            .onAppear(perform: activityViewModel.loadActivities)
        }
    }
}

struct ViewRequestsView: View {
    @StateObject var activityViewModel: ActivityViewModel
    
    var body: some View {
        Section {
            HStack {
                NavigationLink("View Requests", destination: RequestView(userRequests: activityViewModel.userRequests, playlistRequests: activityViewModel.playlistRequests))
                    .foregroundColor(Color("SyncedBlue"))
                let requestCount = activityViewModel.playlistRequests.count + activityViewModel.userRequests.count
                if requestCount > 0 {
                    Text("(\(requestCount))")
                        .foregroundColor(.syncedBlue)
                    Spacer()
                }
            }
        }
    }
}

struct NotificationsView: View {
    @StateObject var activityViewModel: ActivityViewModel
    
    var body: some View {
        Section(header: Text("Notifications")) {
            if activityViewModel.notifications.isEmpty {
                Text("No notifications found")
                    .foregroundColor(.syncedDarkGrey)
            } else {
                ForEach(activityViewModel.notifications, id: \.self) { notification in
                    HStack {
                        Text(notification.message)
                            .padding(.vertical, 0.5)
                        Spacer()
                        Text(activityViewModel.convertTimestamp(notification.createdAt))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView()
    }
}
