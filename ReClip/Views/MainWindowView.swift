// MARK: - ReClip/Views/MainWindowView.swift
// 主窗口视图

import SwiftUI

struct MainWindowView: View {
    @ObservedObject var viewModel: MainViewModel
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            SearchBar(text: $viewModel.searchText)
                .focused($isSearchFocused)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
            
            Divider()
            
            // 列表或空状态
            if viewModel.filteredItems.isEmpty {
                EmptyStateView()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.filteredItems.enumerated()), id: \.element.id) { index, item in
                                ClipRowView(item: item, isSelected: viewModel.isSelected(item))
                                    .id(item.id)
                                    .onTapGesture {
                                        viewModel.selectIndex(index)
                                        viewModel.pasteSelected()
                                    }
                                    .onHover { isHovered in
                                        if isHovered {
                                            viewModel.selectIndex(index)
                                        }
                                    }
                                    .contextMenu {
                                        ClipContextMenu(
                                            item: item,
                                            onCopy: { viewModel.copyItem(item) },
                                            onPaste: { viewModel.pasteItem(item) },
                                            onFavorite: { viewModel.toggleFavorite(item) },
                                            onDelete: { viewModel.deleteItem(item) },
                                            onOpenApp: { viewModel.openSourceApp(item) },
                                            onShowDetail: { viewModel.showDetail(item) }
                                        )
                                    }
                            }
                        }
                    }
                    .onChange(of: viewModel.selectedIndex) { newIndex in
                        if let item = viewModel.selectedItem() {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo(item.id, anchor: .center)
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // 底部提示栏
            FooterBar()
        }
        .frame(width: Constants.UI.windowWidth, height: Constants.UI.windowHeight)
        .background(.ultraThinMaterial)
        .cornerRadius(Constants.UI.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .sheet(isPresented: $viewModel.showDetailView) {
            if let item = viewModel.selectedDetailItem {
                DetailView(item: item)
            }
        }
    }
}

// MARK: - Context Menu

struct ClipContextMenu: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onPaste: () -> Void
    let onFavorite: () -> Void
    let onDelete: () -> Void
    let onOpenApp: () -> Void
    let onShowDetail: (() -> Void)?
    
    var body: some View {
        Group {
            Button("复制到剪贴板") {
                onCopy()
            }
            .keyboardShortcut("c", modifiers: .command)
            
            Button("粘贴到前台应用") {
                onPaste()
            }
            .keyboardShortcut(.defaultAction)
            
            Button("查看详情") {
                onShowDetail?()
            }
            .keyboardShortcut(" ", modifiers: [])
            
            Divider()
            
            Button(item.isFavorite ? "取消收藏" : "收藏") {
                onFavorite()
            }
            .keyboardShortcut("s", modifiers: .command)
            
            Button("删除", role: .destructive) {
                onDelete()
            }
            .keyboardShortcut(.delete, modifiers: [])
            
            if item.appBundleId != nil {
                Divider()
                
                Button("打开来源应用: \(item.appName ?? "未知")") {
                    onOpenApp()
                }
            }
        }
    }
}

#Preview {
    MainWindowView(viewModel: .shared)
        .frame(width: Constants.UI.windowWidth, height: Constants.UI.windowHeight)
}
