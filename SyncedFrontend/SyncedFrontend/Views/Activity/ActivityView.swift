import SwiftUI

struct ActivityView: View {
    @StateObject private var activityViewModel: ActivityViewModel
    
    init() {
        _activityViewModel = StateObject(wrappedValue: ActivityViewModel(activityService: DIContainer.shared.provideActivityService()))
    }
    
    var body: some View {
        NavigationView {
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
                .navigationBarTitle("Activities")
                .onAppear(perform: activityViewModel.loadActivities)
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
        }
    }
}

struct ViewRequestsView: View {
    @StateObject var activityViewModel: ActivityViewModel
    
    var body: some View {
        Section {
            HStack {
                TextLink(title: "View Requests", destination: RequestView(userRequests: activityViewModel.userRequests, playlistRequests: activityViewModel.playlistRequests))
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
