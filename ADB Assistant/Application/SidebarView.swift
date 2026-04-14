import AppKit
import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var deviceListVM: DeviceListViewModel
    @Binding var showPreferences: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            deviceList
        }
    }

    private var header: some View {
        HStack {
            Text("Devices")
                .font(.headline)
            Spacer()
            Button {
                state.refreshDevices()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .help("Refresh connected devices")

            Button {
                showPreferences = true
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .help("Open preferences")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var deviceList: some View {
        ZStack {
            List(selection: deviceSelectionBinding) {
                ForEach(deviceListVM.devices) { device in
                    DeviceRow(
                        device: device
                    )
                    .tag(device.identifier)
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 8))
                }
            }
            .listStyle(SidebarListStyle())
            .padding(.top, 8)

            if deviceListVM.devices.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "iphone.slash")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No devices detected")
                        .foregroundColor(.secondary)
                    Button("Refresh") {
                        state.refreshDevices()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
    }

    private var deviceSelectionBinding: Binding<String?> {
        Binding(
            get: { deviceListVM.selectedDeviceID },
            set: { newValue in
                state.selectDevice(with: newValue)
            }
        )
    }
}

struct DeviceRow: View {
    let device: Device

    var body: some View {
        HStack(spacing: 10) {
            deviceIcon
            VStack(alignment: .leading, spacing: 2) {
                Text(device.model.isEmpty ? "Unknown device" : device.model)
                    .font(.body)
                Text(device.identifier)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var deviceIcon: some View {
        Image(systemName: "iphone")
            .resizable()
            .scaledToFit()
            .foregroundColor(.accentColor)
            .frame(width: 20, height: 20)
    }
}
