import SwiftUI

/// 添加阶段视图的 ViewModel
/// 负责处理添加新阶段的业务逻辑和状态管理
class AddStageViewModel: ObservableObject {
    // MARK: - 属性
    
    /// 可选的阶段列表
    private let availableStages: [InterviewStage]
    
    /// 选中的阶段
    @Published var selectedStage: InterviewStage = .interview
    
    /// 选中的日期
    @Published var selectedDate = Date()
    
    /// 地点类型
    @Published var locationType: LocationType = .online
    
    /// 地点地址
    @Published var address: String = ""
    
    /// 添加完成的回调
    private let onComplete: (InterviewStage, Date, StageLocation?) -> Void
    
    // MARK: - 计算属性
    
    /// 是否可以保存
    var canSave: Bool {
        true
    }
    
    /// 是否需要地点信息
    var needsLocation: Bool {
        [.interview, .written, .hrInterview].contains(selectedStage)
    }
    
    /// 地点提示文本
    var locationPlaceholder: String {
        if locationType == .online {
            return selectedStage == .written ? "笔试链接（选填）" : "会议链接（选填）"
        } else {
            return selectedStage == .written ? "笔试地点（选填）" : "面试地点（选填）"
        }
    }
    
    // MARK: - 初始化方法
    
    /// 初始化方法
    /// - Parameters:
    ///   - availableStages: 可选的阶段列表
    ///   - onComplete: 添加完成的回调
    init(availableStages: [InterviewStage], onComplete: @escaping (InterviewStage, Date, StageLocation?) -> Void) {
        self.availableStages = availableStages
        self.onComplete = onComplete
        
        // 如果有可用的阶段，选择第一个作为默认值
        if let firstStage = availableStages.first {
            self.selectedStage = firstStage
        }
    }
    
    // MARK: - 公共方法
    
    /// 保存阶段
    func save() {
        let location: StageLocation?
        if needsLocation && !address.isEmpty {
            location = StageLocation(type: locationType, address: address)
        } else {
            location = nil
        }
        
        onComplete(selectedStage, selectedDate, location)
    }
    
    /// 获取阶段列表
    /// - Returns: 可选的阶段列表
    func getStages() -> [InterviewStage] {
        availableStages
    }
    
    /// 更新阶段选择
    /// - Parameter stage: 选中的阶段
    func updateStage(_ stage: InterviewStage) {
        selectedStage = stage
    }
    
    /// 更新地点类型
    /// - Parameter type: 新的地点类型
    func updateLocationType(_ type: LocationType) {
        locationType = type
    }
} 