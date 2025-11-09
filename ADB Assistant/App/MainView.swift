import SwiftUI

struct RootView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        if state.platformToolsPath == nil {
            SetupView()
        } else {
            MainView()
        }
    }
}

struct MainView: View {
    @EnvironmentObject private var state: AppState
    @State private var showingPreferences = false

    var body: some View {
        NavigationView {
            SidebarView(showPreferences: $showingPreferences)
                .frame(minWidth: 220)

            DashboardView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("ADB Assistant")
        .sheet(isPresented: $showingPreferences) {
            PreferencesView()
                .frame(minWidth: 460, minHeight: 320)
        }
        .alert(item: $state.alert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message))
        }
        .onAppear {
            state.restartCPUMonitoring()
        }
    }
}
