import SwiftUI

struct EditCollaboratorsView: View {
    @Binding var showSheet: Bool
    
    @StateObject private var editCollaboratorsViewModel: EditCollaboratorsViewModel
    
    init(showSheet: Binding<Bool>, playlistId: String) {
        _showSheet = showSheet
        _editCollaboratorsViewModel = StateObject(wrappedValue: EditCollaboratorsViewModel(playlistId: playlistId, collaborativePlaylistService: DIContainer.shared.provideCollaborativePlaylistService()))
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(editCollaboratorsViewModel.collaborators, id: \.self) { song in
                    
                }
            }
        }
        .navigationBarTitle("Add Songs", displayMode: .inline)
        .toolbar { toolbarContent() }
        .alert("Error", isPresented: Binding<Bool>(
            get: { self.editCollaboratorsViewModel.errorMessage != nil },
            set: { _ in self.editCollaboratorsViewModel.errorMessage = nil }
        ), presenting: editCollaboratorsViewModel.errorMessage) { errorMessage in
            Button("OK", role: .cancel) { }
        } message: { errorMessage in
            Text(errorMessage)
        }
        .accentColor(Color("SyncedBlue"))
        .onAppear(perform: editCollaboratorsViewModel.loadCollaborators)
    }
    
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Done", action: {
                Task {
                    showSheet = false
                }
            })
        }
    }
}
