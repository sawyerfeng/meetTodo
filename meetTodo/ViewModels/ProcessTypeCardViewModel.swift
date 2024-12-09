import SwiftUI

/// 流程类型卡片的 ViewModel
class ProcessTypeCardViewModel: ObservableObject {
    // MARK: - 属性
    
    /// 流程类型
    private let type: ProcessType
    
    /// 是否选中
    private let isSelected: Bool
    
    // MARK: - 计算属性
    
    /// 图标
    var icon: Image {
        type.icon
    }
    
    /// 类型名称
    var typeName: String {
        type.rawValue
    }
    
    /// 背景颜色
    var backgroundColor: Color {
        isSelected ? type.color.opacity(0.1) : Color.gray.opacity(0.1)
    }
    
    /// 图标颜色
    var iconColor: Color {
        isSelected ? type.color : .gray
    }
    
    /// 文字颜色
    var textColor: Color {
        isSelected ? type.color : .gray
    }
    
    // MARK: - 初始化方法
    
    /// 初始化方法
    /// - Parameters:
    ///   - type: 流程类型
    ///   - isSelected: 是否选中
    init(type: ProcessType, isSelected: Bool) {
        self.type = type
        self.isSelected = isSelected
    }
} 
