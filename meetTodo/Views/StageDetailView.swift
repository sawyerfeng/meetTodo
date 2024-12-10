import SwiftUI
import MapKit

struct StageDetailView: View {
    let item: InterviewStageItem
    let availableStages: [InterviewStage]
    let onAction: (StageRowAction) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    @State private var showingMapActionSheet = false
    @State private var showingEditor = false
    @State private var showingDeleteAlert = false
    @State private var showingLinkActionSheet = false
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: item.date)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 顶部阶段信息模块
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.displayName)
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(item.stage.color.opacity(0.1))
                .cornerRadius(10)
                
                // 地址/链接模块
                if let location = item.location {
                    HStack {
                        HStack {
                            Image(systemName: location.type == .offline ? "mappin.circle.fill" : "link.circle.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(location.type == .offline ? "地址" : "链接")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text(location.address)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            
                            if location.type == .offline {
                                Button(action: {
                                    showingMapActionSheet = true
                                }) {
                                    Image(systemName: "arrow.up.forward.app.fill")
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                }
                            } else {
                                Button(action: {
                                    showingLinkActionSheet = true
                                }) {
                                    Image(systemName: "arrow.up.forward.app.fill")
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                // 笔记模块
                VStack(alignment: .leading, spacing: 8) {
                    Text("笔记")
                        .font(.headline)
                    if item.note.isEmpty {
                        Text("暂无笔记")
                            .foregroundColor(.gray)
                    } else {
                        Text(item.note)
                    }
                    Button(action: {
                        onAction(.editNote)
                    }) {
                        Text("编辑笔记")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditor = true
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    
                    Button {
                        onAction(.setStatus(.passed))
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Label("标记为通过", systemImage: "checkmark.circle")
                    }
                    
                    Button {
                        onAction(.setStatus(.failed))
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Label("标记为未通过", systemImage: "xmark.circle")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            StageEditorView(
                stage: item,
                availableStages: availableStages,
                onSave: { newStage, newDate, location in
                    onAction(.update(newStage, newDate, location))
                    presentationMode.wrappedValue.dismiss()
                },
                onDelete: {
                    onAction(.delete)
                    presentationMode.wrappedValue.dismiss()
                },
                onSetStatus: { status in
                    onAction(.setStatus(status))
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .confirmationDialog("选择地图应用", isPresented: $showingMapActionSheet) {
            if let location = item.location {
                Button("在高德地图中打开") {
                    openInAmap(address: location.address)
                }
                Button("在苹果地图中打开") {
                    openInMaps(address: location.address)
                }
                Button("取消", role: .cancel) { }
            }
        }
        .confirmationDialog("选择打开方式", isPresented: $showingLinkActionSheet) {
            if let location = item.location {
                Button("在浏览器中打开") {
                    openInBrowser(urlString: location.address)
                }
                Button("取消", role: .cancel) { }
            }
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("删除", role: .destructive) {
                onAction(.delete)
                presentationMode.wrappedValue.dismiss()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("确定要删除这个阶段吗？此操作无法撤销。")
        }
        .interactiveDismissDisabled()
    }
    
    // 打开地图
    private func openInMaps(address: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let location = placemarks?.first?.location {
                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
                mapItem.name = address
                mapItem.openInMaps()
            }
        }
    }
    
    // 打开高德地图
    private func openInAmap(address: String) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // 尝试使用新版URL Scheme
        let urlString = "amap://poi?sourceApplication=meetTodo&keywords=\(encodedAddress)"
        let backupUrlString = "iosamap://path?sourceApplication=meetTodo&dname=\(encodedAddress)&dev=0&t=0"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url) { success in
                if !success, let backupUrl = URL(string: backupUrlString) {
                    UIApplication.shared.open(backupUrl) { success in
                        if !success {
                            // 如果都无法打开，跳转到App Store
                            if let appStoreURL = URL(string: "https://apps.apple.com/cn/app/id461703208") {
                                UIApplication.shared.open(appStoreURL)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 打开链接
    private func openURL(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
    // 在浏览器中打开链接
    private func openInBrowser(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url, options: [.universalLinksOnly: false]) { success in
            if !success {
                // 如果���法打开，尝试添加 https:// 前缀
                if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
                    let httpsUrl = "https://" + urlString
                    if let secureUrl = URL(string: httpsUrl) {
                        UIApplication.shared.open(secureUrl)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        StageDetailView(
            item: InterviewStageItem(
                stage: .interview,
                interviewRound: 1,
                date: Date(),
                note: "这是一个测试笔记",
                location: StageLocation(type: .offline, address: "北京市朝阳区xxx街道")
            ),
            availableStages: InterviewStage.allCases,
            onAction: { _ in }
        )
    }
}