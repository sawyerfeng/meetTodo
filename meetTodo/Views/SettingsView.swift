import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    init() {
        self._viewModel = StateObject(wrappedValue: SettingsViewModel())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 权限管理
                Section("权限管理") {
                    // 通知权限
                    HStack {
                        Label("通知权限", systemImage: "bell.badge")
                        Spacer()
                        switch viewModel.notificationStatus {
                        case .authorized:
                            Text("已授权")
                                .foregroundColor(.green)
                        case .denied:
                            Button("去设置") {
                                viewModel.openSettings()
                            }
                            .foregroundColor(.blue)
                        case .notDetermined:
                            Button("申请权限") {
                                Task {
                                    await viewModel.requestNotificationPermission()
                                }
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    // 日历权限
                    HStack {
                        Label("日历权限", systemImage: "calendar")
                        Spacer()
                        switch viewModel.calendarStatus {
                        case .authorized:
                            Text("已授权")
                                .foregroundColor(.green)
                        case .denied:
                            Button("去设置") {
                                viewModel.openSettings()
                            }
                            .foregroundColor(.blue)
                        case .notDetermined:
                            Button("申请权限") {
                                Task {
                                    await viewModel.requestCalendarPermission()
                                }
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                // 通知设置
                Section("通知设置") {
                    Toggle("开启通知", isOn: $viewModel.notificationsEnabled)
                        .disabled(!viewModel.canEnableNotifications)
                    
                    if viewModel.notificationsEnabled {
                        Stepper("提前\(viewModel.notificationMinutes)分钟通知",
                               value: $viewModel.notificationMinutes,
                               in: 5...120,
                               step: 5)
                    }
                }
                
                // 日历设置
                Section("日历设置") {
                    Toggle("同步到日历", isOn: $viewModel.calendarSyncEnabled)
                        .disabled(!viewModel.canEnableCalendarSync)
                    
                    if viewModel.calendarSyncEnabled {
                        Picker("选择日历", selection: $viewModel.selectedCalendarId) {
                            ForEach(viewModel.calendars, id: \.calendarIdentifier) { calendar in
                                Text(calendar.title)
                                    .tag(calendar.calendarIdentifier)
                            }
                        }
                    }
                }
                
                // 关于
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.checkPermissions()
            }
            .onChange(of: viewModel.notificationsEnabled) {
                viewModel.handleNotificationToggle()
            }
            .onChange(of: viewModel.calendarSyncEnabled) {
                viewModel.handleCalendarSyncToggle()
            }
            .alert("权限提示", isPresented: $viewModel.showingPermissionAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(viewModel.permissionAlertMessage)
            }
        }
    }
} 