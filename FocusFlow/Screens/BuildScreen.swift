//
//  BuildScreen.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/23.
//

import SwiftUI

struct BuildScreen: View {
    @State var state: BuildState
    
    var body: some View {
        NavigationStack {
            List {
                BuildCanvas(state: state)
                
                Section {
                    Button("Fall") {
                        Task {
                            await state.fallAndClear()
                        }
                    }
                }
            }
            .navigationTitle("Build")
        }
    }
}

struct BuildCanvas: View {
    @Bindable var state: BuildState
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white
                .frame(height: 400)
            ForEach(state.items) { item in
                item.view
                    .offset(item.offset)
            }
        }
    }
}

@Observable
class BuildState {
    var items: [BuildItem]
    
    init(items: [BuildItem]) {
        self.items = items
    }
    
    func fallAndClear() async {
        withAnimation(.easeIn(duration: 1)) {
            for i in items.indices {
                items[i].offset.height = 500
            }
        }
        try? await Task.sleep(for: .seconds(1))
        items.removeAll()
    }
}

struct BuildItem: Identifiable, Equatable {
    let id = UUID()
    var offset: CGSize = .zero
    var content: BuildItemContent
    
    @ViewBuilder var view: some View {
        switch content {
        case .color(let color, let size): color.frame(width: size.width, height: size.height)
        case .image(let name): Image(name)
        }
    }
}

enum BuildItemContent: Equatable {
    case color(Color, frame: CGSize)
    case image(name: String)
}

#Preview {
    @Previewable @State var state = BuildState(items: [
        BuildItem(offset: CGSize(width: 10, height: 50),content: .color(.red, frame: CGSize(width: 100, height: 200))),
        BuildItem(offset: CGSize(width: 200, height: 170),content: .color(.green, frame: CGSize(width: 100, height: 200))),
    ])
    
    TabView {
        Tab("Build", systemImage: "wrench.and.screwdriver") {
            BuildScreen(state: state)
        }
        Tab("Home", systemImage: "house") {}
    }
    .onChange(of: state.items) {
        print(state.items)
    }
}
