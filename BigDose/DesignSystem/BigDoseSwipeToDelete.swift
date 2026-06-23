import SwiftUI

// MARK: - Swipe To Delete

extension View {
    /// Applies a trailing destructive swipe-to-delete action using the system swipe action affordance.
    func bigDoseSwipeToDelete(action: @escaping @MainActor () -> Void) -> some View {
        swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: action) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    /// Coordinates swipe actions across rows in custom scroll containers.
    /// On `List`, this is a no-op because coordination is built in.
    @ViewBuilder
    func bigDoseSwipeActionsContainer() -> some View {
        #if compiler(>=6.4)
        if #available(iOS 27.0, *) {
            swipeActionsContainer()
        } else {
            self
        }
        #else
        self
        #endif
    }

    /// Swipe-to-delete on iOS 27+, long-press delete menu on earlier releases.
    @ViewBuilder
    func bigDoseDeletable(action: @escaping @MainActor () -> Void) -> some View {
        if #available(iOS 27.0, *) {
            bigDoseSwipeToDelete(action: action)
        } else {
            contextMenu {
                Button("Delete", role: .destructive, action: action)
            }
        }
    }
}
