import SwiftUI
import Foundation
import UIKit

struct StageRow: View {
    let item: InterviewStageItem
    let selectedStage: Binding<InterviewStageItem?>
    let onAction: (StageRowAction) -> Void
    @State private var showingMapActionSheet = false
    
    var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: item.date)
    }
    
    // 根据状态获取背景色
    private var backgroundColor: Color {
        switch item.status {
        case .pending:
            return Color.blue.opacity(0.1)
        case .passed:
            return Color.green.opacity(0.1)
        case .failed:
            return Color.yellow.opacity(0.1)
        }
    }
    
    // 根据状态获取边框色
    private var borderColor: Color {
        switch item.status {
        case .pending:
            return Color.blue.opacity(0.3)
        case .passed:
            return Color.green.opacity(0.3)
        case .failed:
            return Color.yellow.opacity(0.3)
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 连接线
            if let _ = selectedStage.wrappedValue {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 2, height: 20)
                    .padding(.leading, 29)
            }
            
            HStack(spacing: 16) {
                // 阶段图标
                Circle()
                    .fill(item.stage.color)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: item.stage.icon)
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    // 阶段名称和状态
                    HStack {
                        Text(item.displayName)
                            .font(.headline)
                        
                        if item.status != .pending {
                            Image(systemName: item.status == .passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(item.status == .passed ? .green : .yellow)
                                .font(.caption)
                        }
                    }
                    
                    // 时间
                    Text(formattedDateTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // 地点（如果有）
                    if let location = item.location {
                        Button {
                            showingMapActionSheet = true
                        } label: {
                            HStack {
                                Image(systemName: location.type == .online ? "link" : "mappin.and.ellipse")
                                    .foregroundColor(.blue)
                                Text(location.address)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // 编辑按钮
                Button {
                    selectedStage.wrappedValue = item
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    onAction(.delete)
                } label: {
                    Label("删除", systemImage: "trash")
                }
                
                Button {
                    onAction(.setStatus(.pending))
                } label: {
                    Label("进行中", systemImage: "clock")
                }
                .tint(.blue)
                
                Button {
                    onAction(.setStatus(.passed))
                } label: {
                    Label("通过", systemImage: "checkmark.circle")
                }
                .tint(.green)
                
                Button {
                    onAction(.setStatus(.failed))
                } label: {
                    Label("未通过", systemImage: "xmark.circle")
                }
                .tint(.yellow)
            }
            
            // 连接线
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 2)
                .padding(.leading, 29)
        }
        .confirmationDialog("选择地图应用", isPresented: $showingMapActionSheet) {
            if let location = item.location {
                Button("在高德地图中打开") {
                    openInAmap(address: location.address)
                }
                Button("在苹果地图中打开") {
                    openInAppleMaps(address: location.address)
                }
                Button("取消", role: .cancel) { }
            }
        }
    }
    
    private func openInAmap(address: String) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "iosamap://poi?sourceApplication=meetTodo&keywords=\(encodedAddress)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openInAppleMaps(address: String) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "http://maps.apple.com/?q=\(encodedAddress)") {
            UIApplication.shared.open(url)
        }
    }
}

enum StageRowAction {
    case update(InterviewStage, Date, StageLocation?)
    case delete
    case setStatus(StageStatus)
} 
