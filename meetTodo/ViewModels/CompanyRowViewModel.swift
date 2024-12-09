import SwiftUI

/// 公司列表项的 ViewModel
@Observable
class CompanyRowViewModel {
    // MARK: - 属性
    
    /// 公司项
    private let item: Item
    
    // MARK: - 计算属性
    
    /// 公司图标
    var icon: Image {
        if let iconData = item.iconData,
           let uiImage = UIImage(data: iconData) {
            return Image(uiImage: uiImage)
        } else {
            return Image(systemName: item.companyIcon)
        }
    }
    
    /// 公司名称
    var companyName: String {
        item.companyName
    }
    
    /// 当前阶段
    var currentStage: String {
        item.currentStage
    }
    
    /// 下一阶段日期
    var nextStageDate: Date? {
        item.nextStageDate
    }
    
    /// 格式化的日期字符串
    var formattedDate: String? {
        guard let date = nextStageDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    /// 状态颜色
    var statusColor: Color {
        item.status.color
    }
    
    /// 进度百分比
    var progressPercentage: Double {
        Double(item.status.percentage) / 100.0
    }
    
    // MARK: - 初始化方法
    
    /// 初始化方法
    /// - Parameter item: 公司项
    init(item: Item) {
        self.item = item
    }
} 