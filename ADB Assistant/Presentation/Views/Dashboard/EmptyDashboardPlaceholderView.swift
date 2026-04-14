import SwiftUI

struct EmptyDashboardPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.grid.2x2")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Select a device to manage")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("Connect an Android device via ADB to access controls and metrics.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
