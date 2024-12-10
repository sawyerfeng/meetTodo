import SwiftUI
import UserNotifications

@MainActor
struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    
    private let reminderOptions = [
        15: "15分钟前",
        30: "30分钟前",
        60: "1小时前",
        120: "2小时前",
        180: "3小时前",
        240: "4小时前",
        1440: "1天前"
    ]
    
    init() {
        self._viewModel = StateObject(wrappedValue: SettingsViewModel())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("开启面试提醒", isOn: $viewModel.enableReminder)
                        .tint(.blue)
                        .onChange(of: viewModel.enableReminder) { _, newValue in
                            Task {
                                await viewModel.handleReminderToggle(newValue)
                            }
                        }
                    
                    if viewModel.enableReminder {
                        Picker("提前提醒时间", selection: $viewModel.reminderMinutes) {
                            ForEach(Array(reminderOptions.keys).sorted(), id: \.self) { minutes in
                                Text(reminderOptions[minutes] ?? "")
                                    .tag(minutes)
                            }
                        }
                    }
                } header: {
                    Text("提醒设置")
                } footer: {
                    Text("关闭后将不会收到面试日程的系统提醒")
                }
                
                Section {
                    Button {
                        viewModel.openNotificationSettings()
                    } label: {
                        HStack {
                            Text("通知权限设置")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button {
                        viewModel.openCalendarSettings()
                    } label: {
                        HStack {
                            Text("日历权限设置")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                } header: {
                    Text("系统设置")
                } footer: {
                    Text("管理应用的系统权限")
                }
            }
            .navigationTitle("设置")
            .alert("通知设置", isPresented: $viewModel.showingNotificationAlert) {
                Button("取消", role: .cancel) { }
                Button("前往设置") {
                    viewModel.openNotificationSettings()
                }
            } message: {
                Text(viewModel.alertMessage)
            }
        }
    }
}

#Preview {
    SettingsView()
} 
