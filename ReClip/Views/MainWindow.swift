// MARK: - ReClip/Views/MainWindow.swift
// 浮动搜索面板

import SwiftUI

struct MainWindow: View {
    @StateObject private var viewModel = MainViewModel()
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $viewModel.searchText)
                .focused($isSearchFocused)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
            
            Divider()
            
            if viewModel.filteredItems.isEmpty {
                EmptyStateView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.filteredItems.enumerated()), id: \.element.id) { index, item in
                            ClipRowView(item: item, isSelected: viewModel.isSelected(item))
                                .onTapGesture {
                                    viewModel.selectIndex(index)
                                    viewModel.pasteSelected()
                                }
                                .onHover { isHovered in
                                    if isHovered {
                                        viewModel.selectIndex(index)
                                    }
                                }
                        }
                    }
                }
            }
            
            Divider()
            
            FooterBar()
        }
        .frame(width: Constants.UI.windowWidth, height: Constants.UI.windowHeight)
        .background(.ultraThinMaterial)
        .cornerRadius(Constants.UI.cornerRadius)
        .shadow(radius: 20)
        .onKeyPress(.upArrow) {
            viewModel.moveUp()
            return .handled
        }
        .onKeyPress(.downArrow) {
            viewModel.moveDown()
            return .handled
        }
        .onKeyPress(.return) {
            viewModel.pasteSelected()
            return .handled
        }
        .onKeyPress(.escape) {
            viewModel.hideWindow()
            return .handled
        }
        .onKeyPress(.delete) {
            viewModel.deleteSelected()
            return .handled
        }
        .onKeyPress("k") {
            viewModel.moveUp()
            return .handled
        }
        .onKeyPress("j") {
            viewModel.moveDown()
            return .handled
        }
    }
}

#Preview {
    MainWindow()
}
