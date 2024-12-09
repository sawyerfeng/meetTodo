import SwiftUI

/// 阶段详情的 ViewModel
class StageDetailViewModel: ObservableObject {
    // MARK: - 属性
    
    /// 阶段项
    private let item: InterviewStageItem
    
    /// 可用的阶段列表
    private let availableStages: [InterviewStage]
    
    /// 阶段操作回调
    private let onAction: (StageRowAction) -> Void
    
    /// 是否显示编辑器
    @Published var showingEditor = false
    
    /// 是否显示地图选择菜单
    @Published var showingMapActionSheet = false
    
    // MARK: - 计算属性
    
    /// 格式化的日期字符串
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: item.date)
    }
    
    // MARK: - 初始化方法
    
    /// 初始化方法
    /// - Parameters:
    ///   - item: 阶段项
    ///   - availableStages: 可用的阶段列表
    ///   - onAction: 阶段操作回调
    init(item: InterviewStageItem, availableStages: [InterviewStage], onAction: @escaping (StageRowAction) -> Void) {
        self.item = item
        self.availableStages = availableStages
        self.onAction = onAction
    }
    
    // MARK: - 公共方法
    
    /// 处理阶段操作
    /// - Parameter action: 操作类型
    func handleAction(_ action: StageRowAction) {
        onAction(action)
    }
    
    /// 在高德地图中打开地址
    /// - Parameter address: 地址
    func openInAmap(address: String) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "iosamap://poi?sourceApplication=meetTodo&keywords=\(encodedAddress)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // 如果没有安装高德地图，打开 App Store
                if let appStoreURL = URL(string: "itms-apps://itunes.apple.com/app/id461703208") {
                    UIApplication.shared.open(appStoreURL)
                }
            }
        }
    }
    
    /// 在苹果地图中打开地址
    /// - Parameter address: 地址
    func openInAppleMaps(address: String) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "http://maps.apple.com/?q=\(encodedAddress)") {
            UIApplication.shared.open(url)
        }
    }
    
    /// 获取阶段项
    /// - Returns: 阶段项
    func getItem() -> InterviewStageItem {
        item
    }
    
    /// 获取可用的阶段列表
    /// - Returns: 可用的阶段列表
    func getAvailableStages() -> [InterviewStage] {
        availableStages
    }
} 
