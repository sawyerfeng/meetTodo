import SwiftUI
import SwiftData

/// 公司详情的 ViewModel
class CompanyDetailViewModel: ObservableObject {
    // MARK: - 属性
    
    /// 公司项
    private let item: Item
    
    /// 阶段列表
    @Published var stages: [InterviewStageItem] = []
    
    /// 选中的图片
    @Published var selectedImage: UIImage?
    
    /// 是否显示图标选择器
    @Published var showingIconPicker = false
    
    /// 是否显示图片选择器
    @Published var showingImagePicker = false
    
    /// 是否显示添加阶段表单
    @Published var showingAddStageSheet = false
    
    /// 是否显示失败提醒
    @Published var showingFailureAlert = false
    
    /// 是否正在编辑名称
    @Published var isEditingName = false
    
    // MARK: - 计算属性
    
    /// 公司名称
    var companyName: String {
        item.companyName
    }
    
    /// 当前阶段
    var currentStage: String {
        item.currentStage
    }
    
    /// 状态颜色
    var statusColor: Color {
        item.status.color
    }
    
    /// 进度百分比
    var progressPercentage: Double {
        Double(item.status.percentage) / 100.0
    }
    
    /// 公司图标
    var icon: Image {
        if let iconData = item.iconData,
           let uiImage = UIImage(data: iconData) {
            return Image(uiImage: uiImage)
        } else {
            return Image(systemName: item.companyIcon)
        }
    }
    
    /// 当前图标名称
    var iconName: String {
        item.companyIcon
    }
    
    // MARK: - 初始化方法
    
    /// 初始化方法
    /// - Parameter item: 公司项
    init(item: Item) {
        self.item = item
        self.stages = item.stages.map { stageData in
            InterviewStageItem(
                id: UUID(uuidString: stageData.id) ?? UUID(),
                stage: InterviewStage(rawValue: stageData.stage) ?? .resume,
                interviewRound: stageData.interviewRound,
                date: stageData.date,
                note: stageData.note,
                status: StageStatus(rawValue: stageData.status) ?? .pending,
                location: stageData.location
            )
        }
    }
    
    // MARK: - 公共方法
    
    /// 获取可用的阶段列表
    /// - Returns: 可用的阶段列表
    func getAvailableStages() -> [InterviewStage] {
        let existingStages = Set(stages.map { $0.stage })
        let hasResume = existingStages.contains(.resume)
        let hasWritten = existingStages.contains(.written)
        let hasInterview = existingStages.contains(.interview)
        let hasOffer = existingStages.contains(.offer)
        
        return InterviewStage.allCases.filter { stage in
            switch stage {
            case .resume:
                return !hasResume
            case .written:
                return hasResume && !hasWritten
            case .interview:
                return hasResume && !hasOffer
            case .hrInterview:
                return hasInterview && !hasOffer
            case .offer:
                return hasResume && !hasOffer
            }
        }
    }
    
    /// 获取可编辑的阶段列表
    /// - Parameter currentStage: 当前阶段
    /// - Returns: 可编辑的阶段列表
    func getAvailableStagesForEdit(_ currentStage: InterviewStage) -> [InterviewStage] {
        var stages = getAvailableStages()
        stages.append(currentStage)
        return stages
    }
    
    /// 处理阶段操作
    /// - Parameters:
    ///   - stage: 阶段项
    ///   - action: 操作类型
    func handleStageAction(_ stage: InterviewStageItem, _ action: StageRowAction) {
        guard let index = stages.firstIndex(where: { $0.id == stage.id }) else { return }
        
        switch action {
        case .setStatus(let newStatus):
            if newStatus == .passed {
                for i in 0...index {
                    stages[i].status = .passed
                }
            } else {
                stages[index].status = newStatus
            }
            
            if newStatus == .failed {
                showingFailureAlert = true
            }
            updateItemStatus()
            
        case .update(let newStage, let newDate, let location):
            stages[index].stage = newStage
            stages[index].date = newDate
            stages[index].location = location
            updateItemStatus()
            
        case .delete:
            stages.remove(at: index)
            updateItemStatus()
        }
        
        // 保存到数据库
        saveStages()
    }
    
    /// 添加新阶段
    /// - Parameters:
    ///   - stage: 阶段类型
    ///   - date: 日期
    ///   - location: 地点信息
    func addStage(stage: InterviewStage, date: Date, location: StageLocation?) {
        // 创建新阶段
        var newStage = InterviewStageItem(
            stage: stage,
            date: date,
            location: location
        )
        
        // 如果是面试，设置轮次
        if stage == .interview {
            let existingInterviews = stages.filter { $0.stage == .interview }
            newStage.interviewRound = (existingInterviews.count + 1)
        }
        
        // 添加到列表
        withAnimation {
            stages.append(newStage)
            updateItemStatus()
        }
        
        // 保存到数据库
        saveStages()
    }
    
    /// 更新公司名称
    /// - Parameter newName: 新名称
    func updateCompanyName(_ newName: String) {
        item.companyName = newName
        isEditingName = false
    }
    
    /// 更新公司图标
    /// - Parameter image: 新图标
    func updateIcon(_ image: UIImage) {
        selectedImage = image
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            item.iconData = imageData
        }
    }
    
    /// 更新公司系统图标
    /// - Parameter iconName: 新图标名称
    func updateSystemIcon(_ iconName: String) {
        item.companyIcon = iconName
        item.iconData = nil
        selectedImage = nil
    }
    
    // MARK: - 私有方法
    
    /// 保存阶段到数据库
    private func saveStages() {
        item.stages = stages.map { stage in
            InterviewStageData(
                id: stage.id.uuidString,
                stage: stage.stage.rawValue,
                interviewRound: stage.interviewRound,
                date: stage.date,
                note: stage.note,
                status: stage.status.rawValue,
                location: stage.location
            )
        }
    }
    
    /// 更新项目状态
    private func updateItemStatus() {
        let sortedStages = stages.sorted { stage1, stage2 in
            let stageOrder: [InterviewStage] = [
                .resume,
                .written,
                .interview,
                .hrInterview,
                .offer
            ]
            
            let index1 = stageOrder.firstIndex(of: stage1.stage) ?? 0
            let index2 = stageOrder.firstIndex(of: stage2.stage) ?? 0
            
            if index1 == index2 {
                if stage1.stage == .interview {
                    return (stage1.interviewRound ?? 0) > (stage2.interviewRound ?? 0)
                }
                return stage1.date > stage2.date
            }
            return index1 > index2
        }
        
        guard let latestStage = sortedStages.first else {
            item.currentStage = "未开始"
            item.status = .pending
            item.nextStageDate = nil
            return
        }
        
        switch latestStage.status {
        case .pending:
            item.currentStage = latestStage.displayName
            item.nextStageDate = latestStage.date
            updateStatusFromStage(latestStage)
            
        case .passed:
            item.currentStage = "\(latestStage.displayName)已通过"
            item.nextStageDate = nil
            updateStatusFromStage(latestStage)
            
        case .failed:
            item.currentStage = "\(latestStage.displayName)未通过"
            item.nextStageDate = nil
            item.status = .failed
        }
    }
    
    /// 根据阶段更新状态
    /// - Parameter stage: 阶段项
    private func updateStatusFromStage(_ stage: InterviewStageItem) {
        switch stage.stage {
        case .resume:
            item.status = .resume
        case .written:
            item.status = .written
        case .interview:
            item.status = .interview
        case .hrInterview:
            item.status = .hrInterview
        case .offer:
            item.status = stage.status == .passed ? .success : .offer
        }
    }
} 