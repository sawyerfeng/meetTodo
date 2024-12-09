import SwiftUI

struct ProcessTypeCard: View {
    @StateObject private var viewModel: ProcessTypeCardViewModel
    
    init(type: ProcessType, isSelected: Bool) {
        _viewModel = StateObject(wrappedValue: ProcessTypeCardViewModel(
            type: type,
            isSelected: isSelected
        ))
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(viewModel.backgroundColor)
                .frame(width: 44, height: 44)
                .overlay {
                    viewModel.icon
                        .foregroundColor(viewModel.iconColor)
                }
            
            Text(viewModel.typeName)
                .font(.caption)
                .foregroundColor(viewModel.textColor)
        }
        .frame(width: 60)
    }
} 