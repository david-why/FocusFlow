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
        print("adding rectangle")
        modelContext.insert(BuildingItem(content: .rect(color: .red), offsetX: 0, offsetY: 0, zIndex: 0, width: 100, height: 100, rotation: 0))
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
            Color.clear
            ForEach(items) { item in
                BuildItemView(item: item)
            }
        }
        .frame(height: 400)
    }
}

struct BuildItemView: View {
    @Bindable var item: BuildingItem
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var dragStartOffset: CGSize? = nil
    @State private var isPopoverOpen = false
    @State private var isResizing = false
    @State private var resizeStartSize: CGSize? = nil
    
    var body: some View {
        item.view
            .popover(isPresented: $isPopoverOpen, attachmentAnchor: .rect(.bounds)) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button("Delete", role: .destructive) {
                            deleteItem()
                        }
                        .buttonStyle(.bordered)
                        Button("Resize") {
                            resizeItem()
                        }
                        .buttonStyle(.bordered)
                    }
                    if hasColor {
                        ColorPicker("Color", selection: colorBinding)
                    }
                }
                .presentationCompactAdaptation(.popover)
                .padding()
            }
            .overlay(alignment: .bottomTrailing) {
                if isResizing {
                    resizeHandle
                }
            }
            .offset(x: item.offsetX, y: item.offsetY)
            .zIndex(item.zIndex)
            .onTapGesture(perform: resizeItem)
            .onLongPressGesture(perform: openMenu)
            .gesture(drag)
    }
    
    @ViewBuilder var resizeHandle: some View {
        GeometryReader { proxy in
            Circle()
                .fill(.blue)
                .frame(width: 8, height: 8)
                .position(x: item.width, y: item.height)
                .gesture(resize)
        }
    }
    
    var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                print("Drag changed \(value.translation)")
                if let dragStartOffset {
                    item.offsetX = dragStartOffset.width + value.location.x - value.startLocation.x
                    item.offsetY = dragStartOffset.height + value.translation.height
                } else {
                    dragStartOffset = CGSize(width: item.offsetX, height: item.offsetY)
                }
            }
            .onEnded { _ in
                print("Drag ended")
                dragStartOffset = nil
            }
    }
    
    var resize: some Gesture {
        DragGesture()
            .onChanged { value in
                print("Resize changed \(value.translation)")
                if let resizeStartSize {
                    item.width = resizeStartSize.width + value.translation.width
                    item.height = resizeStartSize.height + value.translation.height
                } else {
                    resizeStartSize = CGSize(width: item.width, height: item.height)
                }
            }
            .onEnded { value in
                print("Resize ended")
                resizeStartSize = nil
                isResizing = false
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
            case .rect(let color):
                color.color
            default:
                Color.clear
            }
        } set: { color in
            switch item.content {
            case .rect:
                item.content = .rect(color: .init(color))
            default:
                break
            }
        }
    }
    
    func openMenu() {
        isPopoverOpen.toggle()
    }
    
    func deleteItem() {
        print("Deleting item \(item)")
        modelContext.delete(item)
    }
    
    func resizeItem() {
        isResizing.toggle()
        isPopoverOpen = false
    }
}

extension BuildingItem {
    @ViewBuilder var view: some View {
        switch content {
        case .image(let name):
            Image(name)
                .frame(width: width, height: height)
                .rotationEffect(.degrees(rotation))
        case .rect(let color):
            Rectangle()
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
