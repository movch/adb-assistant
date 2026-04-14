import Foundation

struct AppAlert: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
}
