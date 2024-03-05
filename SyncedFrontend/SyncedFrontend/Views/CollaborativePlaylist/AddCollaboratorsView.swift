import SwiftUI

struct AddCollaboratorsView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var searchText = ""
    @StateObject private var addCollaboratorsViewModel: AddCollaboratorViewModel
    @FocusState private var isTextFieldFocused: Bool

    init(playlistId: String, currentCollaborators: [UserMetadata]) {
        _addCollaboratorsViewModel = StateObject(wrappedValue: AddCollaboratorViewModel(playlistId: playlistId, currentCollaborators: currentCollaborators, collaborativePlaylistService: DIContainer.shared.provideCollaborativePlaylistService(), userService: DIContainer.shared.provideUserService()))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Form{
                    UserSelect(
                        collaborators: $addCollaboratorsViewModel.selectedCollaborators,
                        searchCollaborators: addCollaboratorsViewModel.searchUsers
                    )
                }
            }
            .toolbar{ toolbarContent() }
            .navigationBarTitle("Add Collaborators", displayMode: .inline)
            .alert("Error", isPresented: Binding<Bool>(
                get: { self.addCollaboratorsViewModel.errorMessage != nil },
                set: { _ in self.addCollaboratorsViewModel.errorMessage = nil }
            ), presenting: addCollaboratorsViewModel.errorMessage) { errorMessage in
                Button("OK", role: .cancel) {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: { errorMessage in
                Text(errorMessage)
            }
        }
        .navigationBarBackButtonHidden(true)
        .accentColor(Color("SyncedBlue"))
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            ZStack {
                Button("Add") {
                    Task {
                        await addCollaboratorsViewModel.addCollaborators()
                        DispatchQueue.main.async {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .disabled(addCollaboratorsViewModel.isSaving)
                .opacity(addCollaboratorsViewModel.isSaving ? 0 : 1)
                
                if addCollaboratorsViewModel.isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
        }
    }
    
    private func errorAlert() -> Alert {
        Alert(
            title: Text("Error"),
            message: Text(addCollaboratorsViewModel.errorMessage ?? "Unknown error"),
            dismissButton: .default(Text("OK"), action: {
                // Clear the error message here
                addCollaboratorsViewModel.errorMessage = nil
            })
        )
    }
}

struct AddCollaboratorsView_Previews: PreviewProvider {
    static var previews: some View {
        AddCollaboratorsView(playlistId: "", currentCollaborators: [])
    }
}
