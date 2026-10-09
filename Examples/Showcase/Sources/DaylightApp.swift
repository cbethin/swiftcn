import SwiftUI
import SwiftCN

struct DaylightApp: View {
    @Bindable var store: ShowcaseStore
    let exit: () -> Void
    @State private var editor = false
    @State private var projectEditor = false
    @State private var project = "All"
    @State private var showCompleted = false
    @State private var selectedProject: String?
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var complete: Int { store.data.tasks.filter(\.done).count }
    private var filtered: [DayTask] { store.data.tasks.filter { ($0.done == showCompleted) && (project == "All" || $0.project == project) } }
    var body: some View {
        TabView {
            NavigationStack {
                Page {
                    PageHeading(eyebrow: Date().formatted(.dateTime.weekday(.wide).month().day()), title: "A little room\nto focus.", subtitle: "One thing at a time is enough.")
                    Surface(classes: "bg-accent border-0") {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("YOUR DAY, AT A GLANCE").tracking(1.5).tw("text-xs text-primary font-semibold")
                                Text("\(complete) of \(store.data.tasks.count) things done").tw("text-xl font-semibold")
                            }
                            Spacer()
                            Image(systemName: "sun.max").font(.system(size: 40, weight: .ultraLight)).tw("text-primary")
                        }
                        CNProgress("Daily progress", value: Double(complete), total: Double(max(1, store.data.tasks.count)))
                    }
                    Picker("Project", selection: $project) {
                        ForEach(["All", "Personal", "Studio"], id: \.self) { Text($0).tag($0) }
                    }.pickerStyle(.segmented)
                    HStack {
                        SectionHeading(title: showCompleted ? "Well done" : "Up next", detail: "\(filtered.count) tasks")
                        CNButton(variant: .ghost, size: .icon) { editor = true } label: { Image(systemName: "plus") }
                            .accessibilityLabel("Add task").accessibilityIdentifier("add-task")
                            .sourceSheet(isPresented: $editor) { TaskEditor(store: store) }
                    }
                    taskList
                    CNButton(showCompleted ? "Show open tasks" : "Show completed", variant: .ghost) { showCompleted.toggle() }
                        .accessibilityIdentifier("toggle-completed")
                }.modifier(DemoToolbar(app: .daylight, exit: exit))
            }.tabItem { Label("Today", systemImage: "sun.max") }
            // Keep native widths unconstrained so Duo can align both panes with the hinge.
            NavigationSplitView {
                List(selection: $selectedProject) {
                    PageHeading(eyebrow: "Make it yours", title: "Life, in chapters.", subtitle: "Make room for what matters.").collectionRow()
                    ForEach(["Personal", "Studio"], id: \.self) { name in
                        NavigationLink(value: name) {
                            VStack(alignment: .leading, spacing: 16) {
                                Image(systemName: name == "Studio" ? "pencil.and.outline" : "leaf").tw("text-primary text-2xl")
                                Text(name).font(.system(.title2, design: .serif)).tw("text-foreground")
                                CNBadge("\(store.data.tasks.filter { $0.project == name && !$0.done }.count) open", variant: .secondary)
                            }.tw("p-5 w-full bg-surface rounded-[24] border")
                        }.collectionRow()
                    }
                }.collectionStyle().accessibilityIdentifier("project-collection")
                    .modifier(DemoToolbar(app: .daylight, exit: exit))
            } detail: {
                Page {
                    if let name = selectedProject {
                        PageHeading(eyebrow: "One small step", title: name, subtitle: name == "Studio" ? "Give your ideas a little space." : "The things that make a day yours.")
                        Surface {
                            SectionHeading(title: "Your next steps", detail: "\(store.data.tasks.filter { $0.project == name }.count) tasks")
                            ForEach(store.data.tasks.filter { $0.project == name }) { task in taskRow(task) }
                            CNButton("Add task", variant: .outline) { projectEditor = true }
                                .sourceSheet(isPresented: $projectEditor) { TaskEditor(store: store, project: name) }
                        }
                    } else { EmptyMessage(symbol: "square.stack.3d.up", title: "Choose a chapter", message: "Keep your personal plans and studio work in their own space.") }
                }.navigationTitle(selectedProject ?? "Projects").navigationBarTitleDisplayMode(.inline)
            }
                .onChange(of: sizeClass, initial: true) { _, value in
                    if value == .regular && selectedProject == nil { selectedProject = "Personal" }
                }
                .tabItem { Label("Projects", systemImage: "square.stack.3d.up") }
        }
    }
    @ViewBuilder private var taskList: some View {
        if filtered.isEmpty {
            EmptyMessage(symbol: "checkmark.seal", title: "A clear page", message: showCompleted ? "Completed tasks will appear here." : "Nothing waiting. Add something, or enjoy the pause.")
        } else {
            Surface {
                ForEach(filtered) { task in
                    taskRow(task)
                    if task.id != filtered.last?.id { CNSeparator() }
                }
            }
        }
    }
    private func taskRow(_ task: DayTask) -> some View {
        HStack(spacing: 12) {
            CNCheckbox(isOn: Binding(get: { store.data.tasks.first { $0.id == task.id }?.done ?? false }, set: { done in
                if let index = store.data.tasks.firstIndex(where: { $0.id == task.id }) {
                    withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) { store.data.tasks[index].done = done }
                }
            })) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(task.title).strikethrough(task.done).tw("text-sm font-medium")
                    Text("\(task.project) · \(task.date.formatted(.dateTime.month(.abbreviated).day()))").tw("text-xs text-mutedForeground")
                }
            }.accessibilityIdentifier("task-\(task.title)")
            Menu {
                Button("Move to \(task.project == "Studio" ? "Personal" : "Studio")") {
                    if let index = store.data.tasks.firstIndex(where: { $0.id == task.id }) { store.data.tasks[index].project = task.project == "Studio" ? "Personal" : "Studio" }
                }
                Button("Delete task", role: .destructive) { store.data.tasks.removeAll { $0.id == task.id } }
            } label: { Image(systemName: "ellipsis").tw("min-w-[44] min-h-[44] text-mutedForeground") }
                .accessibilityLabel("Task actions for \(task.title)")
        }
    }
}
private struct TaskEditor: View {
    let store: ShowcaseStore
    @State private var title = ""
    @State private var project = "Personal"
    @State private var date = Date()
    init(store: ShowcaseStore, project: String = "Personal") {
        self.store = store
        _project = State(initialValue: project)
    }
    var body: some View {
        EditorSheet(title: "A new task", canSave: !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
            let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return false }
            store.data.tasks.append(.init(title: name, project: project, date: date))
            return true
        } content: {
            PageHeading(eyebrow: "One small step", title: "What’s on your mind?", subtitle: "Give it a name. Make a little space.")
            CNField { CNFieldLabel("Task"); CNInput("Task name", text: $title).accessibilityIdentifier("task-title") }
            CNField {
                CNFieldLabel("Project")
                Picker("Project", selection: $project) { Text("Personal").tag("Personal"); Text("Studio").tag("Studio") }.pickerStyle(.segmented)
            }
            CNDatePicker("Planned for", selection: $date)
        }
    }
}
