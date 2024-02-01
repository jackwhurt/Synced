import SwiftUI

struct ActivityView: View {
    @StateObject private var activityViewModel: ActivityViewModel
    
    init() {
        _activityViewModel = StateObject(wrappedValue: ActivityViewModel(activityService: DIContainer.shared.provideActivityService()))
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextLink(title: "View Requests", destination: RequestView())
                }

                Section(header: Text("Notifications")) {
                    ForEach(activityViewModel.notifications, id: \.self) { notification in
                        HStack {
                            Text(notification.message)
                                .padding(.vertical, 0.5)
                            Spacer()
                            Text(activityViewModel.convertTimestamp(notification.createdAt))
                                .foregroundColor(.syncedDarkGrey)
                        }
                    }
                }
            }
            .navigationBarTitle("Activities")
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

struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView()
    }
}
