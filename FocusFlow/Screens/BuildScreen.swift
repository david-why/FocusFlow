//
//  BuildScreen.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/23.
//

import SwiftUI
import SwiftData
import PhotosUI

struct BuildScreen: View {
    @Environment(\.modelContext) var modelContext
    @Environment(StoreService.self) var storeService
    
    @AppStorage("hasFailedBuild") var hasFailedBuild = false
    
    @Query var items: [BuildingItem]
    
    @State var isPresentingFailedAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                BuildCanvas()
                
                Section {
                    Text("Objects: \(items.count) of \(totalObjects) total")
                    Menu("Add something...") {
                        Button("🟥 Rectangle", action: addRectangleAction)
                        Button("🔺 Triangle", action: addTriangleAction)
                    }
                    .disabled(items.count >= totalObjects)
                    Button("Failed", role: .destructive) {
                        hasFailedBuild = true
                    }
                }
            }
            .navigationTitle("Build")
        }
        .onChange(of: hasFailedBuild, initial: true, checkHasFailed)
        .alert("You have failed...", isPresented: $isPresentingFailedAlert) {
            Button("It won't happen again!") {}
        } message: {
            Text("You failed a focus session, and everything you've built fell to ashes... Better luck next time :(")
        }
    }
    
    var totalObjects: Int {
        storeService.count(of: "build-item")
    }
    
    func checkHasFailed() {
        if hasFailedBuild {
            Task {
                isPresentingFailedAlert = true
                await fallAndClear()
                hasFailedBuild = false
            }
        }
    }
    
    func addRectangleAction() {
        modelContext.insert(BuildingItem(content: .rect(width: 100, height: 100, rotation: 0, color: .red), offsetX: 0, offsetY: 0, zIndex: 0))
    }
    
    func addTriangleAction() {
//        modelContext.insert(BuildingItem(content: .rect(width: 100, height: 100, rotation: 0, color: .red), offsetX: 0, offsetY: 0, zIndex: 0))
    }
    
    func fallAndClear() async {
        withAnimation(.easeIn(duration: 1)) {
            for i in items.indices {
                items[i].offsetY = 500
            }
        }
        try? await Task.sleep(for: .seconds(1))
        items.forEach(modelContext.delete)
    }
}

struct BuildCanvas: View {
    @Query var items: [BuildingItem]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white
                .frame(height: 400)
            ForEach(items) { item in
                BuildItemView(item: item)
            }
        }
    }
}

struct BuildItemView: View {
    @Bindable var item: BuildingItem
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var dragStartOffset: CGSize? = nil
    @State private var isPopoverOpen = false
    
    var body: some View {
        item.view
            .popover(isPresented: $isPopoverOpen) {
                VStack(alignment: .leading, spacing: 4) {
                    Button("Delete", role: .destructive) {
                        deleteItem()
                        
                    }
                    if hasColor {
                        ColorPicker("Color", selection: colorBinding)
                    }
                }
                .presentationCompactAdaptation(.popover)
                .padding(.horizontal)
            }
            .offset(x: item.offsetX, y: item.offsetY)
            .zIndex(item.zIndex)
            .onTapGesture(perform: onTap)
            .gesture(drag)
    }
    
    var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                if let dragStartOffset {
                    item.offsetX = dragStartOffset.width + value.translation.width
                    item.offsetY = dragStartOffset.height + value.translation.height
                } else {
                    dragStartOffset = CGSize(width: item.offsetX, height: item.offsetY)
                }
            }
            .onEnded { _ in
                dragStartOffset = nil
            }
    }
    
    var hasColor: Bool {
        switch item.content {
        case .image: false
        default: true
        }
    }
    
    var colorBinding: Binding<Color> {
        Binding {
            switch item.content {
            case .rect(_, _, _, let color):
                color.color
            default:
                Color.clear
            }
        } set: { color in
            switch item.content {
            case let .rect(width, height, rotation, _):
                item.content = .rect(width: width, height: height, rotation: rotation, color: .init(color))
            default:
                break
            }
        }
    }
    
    func onTap() {
        isPopoverOpen.toggle()
    }
    
    func deleteItem() {
        print("Deleting item \(item)")
        modelContext.delete(item)
    }
}

extension BuildingItem {
    @ViewBuilder var view: some View {
        switch content {
//        case .color(let color, let size): color.frame(width: size.width, height: size.height)
        case .image(let name):
            Image(name)
        case .rect(let width, let height, let rotation, let color): Rectangle()
                .frame(width: width, height: height)
                .rotationEffect(.degrees(rotation))
                .foregroundStyle(color.color)
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: BuildingItem.self, configurations: .init(isStoredInMemoryOnly: true))
    let context = container.mainContext
    
    TabView {
        Tab("Build", systemImage: "wrench.and.screwdriver") {
            BuildScreen()
        }
        Tab("Home", systemImage: "house") {}
    }
    .modelContainer(container)
    .environment(StoreService())
    .onAppear {
//        context.insert(BuildingItem(content: .image(name: "coin"), offsetX: 0, offsetY: 0, zIndex: 1))
//        context.insert(BuildingItem(content: .image(name: "coin"), offsetX: 100, offsetY: 0, zIndex: 1))
    }
}
