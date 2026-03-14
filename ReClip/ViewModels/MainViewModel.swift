// MARK: - ReClip/ViewModels/MainViewModel.swift
// 主窗口视图模型

import Foundation
import Combine
import AppKit

@MainActor
final class MainViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var filteredItems: [ClipboardItem] = []
    @Published var selectedIndex: Int = 0
    @Published var isWindowVisible: Bool = false
    
    private let storage: ClipboardStorage
    private let monitor: ClipboardMonitor
    private let pasteService: PasteService
    private let hotkeyManager: HotkeyManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    init() {
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
        loadItems()
        NSApp.activate(ignoringOtherApps: true)
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
    
    func selectIndex(_ index: Int) {
        guard index >= 0 && index < filteredItems.count else { return }
        selectedIndex = index
    }
    
    func isSelected(_ item: ClipboardItem) -> Bool {
        guard selectedIndex < filteredItems.count else { return false }
        return filteredItems[selectedIndex].id == item.id
    }
    
    // MARK: - Actions
    
    func pasteSelected() {
        guard selectedIndex < filteredItems.count else { return }
        let item = filteredItems[selectedIndex]
        
        hideWindow()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.pasteService.copyAndPaste(item)
        }
    }
    
    func copySelected() {
        guard selectedIndex < filteredItems.count else { return }
        let item = filteredItems[selectedIndex]
        pasteService.copyToClipboard(item)
        hideWindow()
    }
    
    func deleteSelected() {
        guard selectedIndex < filteredItems.count else { return }
        let item = filteredItems[selectedIndex]
        storage.delete(item)
    }
    
    func toggleFavoriteSelected() {
        guard selectedIndex < filteredItems.count else { return }
        let item = filteredItems[selectedIndex]
        storage.toggleFavorite(item)
    }
    
    func selectQuick(_ index: Int) {
        guard index < filteredItems.count else { return }
        selectedIndex = index
        pasteSelected()
    }
}
