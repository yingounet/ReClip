// MARK: - ReClip/ViewModels/MainViewModel.swift
// 主窗口视图模型（单例模式）

import Foundation
import Combine
import AppKit

@MainActor
final class MainViewModel: ObservableObject {
    
    // MARK: - Singleton
    static let shared = MainViewModel()
    
    // MARK: - Published Properties
    @Published var searchText: String = ""
    @Published var filteredItems: [ClipboardItem] = []
    @Published var selectedIndex: Int = 0
    @Published var isWindowVisible: Bool = false
    @Published var isSearchFocused: Bool = true
    @Published var selectedDetailItem: ClipboardItem? = nil
    @Published var showDetailView: Bool = false
    
    // MARK: - Private Properties
    private let storage: ClipboardStorage
    private let monitor: ClipboardMonitor
    private let pasteService: PasteService
    private let hotkeyManager: HotkeyManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    private init() {
        self.storage = .shared
        self.monitor = .shared
        self.pasteService = .shared
        self.hotkeyManager = .shared
        
        setupBindings()
        loadItems()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        storage.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.applyFilter(items: items)
            }
            .store(in: &cancellables)
        
        $searchText
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyFilter(items: self?.storage.items ?? [])
            }
            .store(in: &cancellables)
        
        hotkeyManager.onShowMainWindow = { [weak self] in
            Task { @MainActor in
                self?.toggleWindow()
            }
        }
    }
    
    private func loadItems() {
        filteredItems = storage.items
    }
    
    private func applyFilter(items: [ClipboardItem]) {
        if searchText.isEmpty {
            filteredItems = items
        } else {
            filteredItems = storage.search(query: searchText)
        }
        
        if selectedIndex >= filteredItems.count {
            selectedIndex = max(0, filteredItems.count - 1)
        }
    }
    
    // MARK: - Window Management
    
    func showWindow() {
        isWindowVisible = true
        selectedIndex = 0
        searchText = ""
        isSearchFocused = true
        loadItems()
    }
    
    func hideWindow() {
        isWindowVisible = false
    }
    
    func toggleWindow() {
        if isWindowVisible {
            hideWindow()
        } else {
            showWindow()
        }
    }
    
    func focusSearch() {
        isSearchFocused = true
    }
    
    // MARK: - Navigation
    
    func moveUp() {
        if selectedIndex > 0 {
            selectedIndex -= 1
        }
    }
    
    func moveDown() {
        if selectedIndex < filteredItems.count - 1 {
            selectedIndex += 1
        }
    }
    
    func moveToTop() {
        selectedIndex = 0
    }
    
    func moveToBottom() {
        if !filteredItems.isEmpty {
            selectedIndex = filteredItems.count - 1
        }
    }
    
    func selectIndex(_ index: Int) {
        guard index >= 0 && index < filteredItems.count else { return }
        selectedIndex = index
    }
    
    func isSelected(_ item: ClipboardItem) -> Bool {
        guard selectedIndex < filteredItems.count else { return false }
        return filteredItems[selectedIndex].id == item.id
    }
    
    func selectedItem() -> ClipboardItem? {
        guard selectedIndex < filteredItems.count else { return nil }
        return filteredItems[selectedIndex]
    }
    
    // MARK: - Actions
    
    func pasteSelected() {
        guard let item = selectedItem() else { return }
        
        hideWindow()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.pasteService.copyAndPaste(item)
        }
    }
    
    func copySelected() {
        guard let item = selectedItem() else { return }
        pasteService.copyToClipboard(item)
    }
    
    func deleteSelected() {
        guard let item = selectedItem() else { return }
        storage.delete(item)
        
        // 调整选中索引
        if selectedIndex >= filteredItems.count && selectedIndex > 0 {
            selectedIndex -= 1
        }
    }
    
    func toggleFavoriteSelected() {
        guard let item = selectedItem() else { return }
        storage.toggleFavorite(item)
    }
    
    func selectQuick(_ index: Int) {
        guard index >= 0 && index < filteredItems.count else { return }
        selectedIndex = index
        pasteSelected()
    }
    
    // MARK: - Item Actions
    
    func deleteItem(_ item: ClipboardItem) {
        storage.delete(item)
    }
    
    func toggleFavorite(_ item: ClipboardItem) {
        storage.toggleFavorite(item)
    }
    
    func copyItem(_ item: ClipboardItem) {
        pasteService.copyToClipboard(item)
    }
    
    func pasteItem(_ item: ClipboardItem) {
        hideWindow()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.pasteService.copyAndPaste(item)
        }
    }
    
    func openSourceApp(_ item: ClipboardItem) {
        guard let bundleId = item.appBundleId else { return }
        
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Detail View
    
    func showDetail(_ item: ClipboardItem) {
        selectedDetailItem = item
        showDetailView = true
    }
    
    func showSelectedDetail() {
        guard let item = selectedItem() else { return }
        showDetail(item)
    }
    
    func hideDetail() {
        showDetailView = false
        selectedDetailItem = nil
    }
}
