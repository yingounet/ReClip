// MARK: - ReClip/Views/Components/ToastView.swift
// Toast 提示视图

import SwiftUI

struct ToastView: View {
    let message: String
    let icon: String?
    
    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
            }
            
            Text(message)
                .font(.system(size: 14))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .shadow(radius: 4)
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let icon: String?
    let duration: TimeInterval
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                VStack {
                    Spacer()
                    
                    ToastView(message: message, icon: icon)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                withAnimation {
                                    isPresented = false
                                }
                            }
                        }
                }
            }
        }
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String, icon: String? = nil, duration: TimeInterval = 2) -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message, icon: icon, duration: duration))
    }
}

#Preview {
    ToastView(message: "已复制到剪贴板", icon: "checkmark.circle.fill")
}
