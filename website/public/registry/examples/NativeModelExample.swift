import SwiftUI
import Observation
import SwiftCN

@MainActor @Observable final class WorkspaceFormModel {
    var name = "Studio"
    var notifications = true
    var category: String? = "team"
    var query = ""
    var toasts: [CNToast] = []
    var savedName = ""
    var canSave: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    func save() {
        guard canSave else { return }
        savedName = name
        toasts.append(CNToast(title: "Workspace saved", message: name))
    }
}

struct NativeModelExample: View {
    @State private var model = WorkspaceFormModel()
    var body: some View { WorkspaceForm(model: model) }
}

private struct WorkspaceForm: View {
    @Bindable var model: WorkspaceFormModel
    @FocusState private var nameFocused: Bool
    private let categories = [CNOption("personal", title: "Personal", systemImage: "person"),
                              CNOption("team", title: "Team", systemImage: "person.2")]
    var body: some View {
        CNToastHost(toasts: $model.toasts) {
            VStack(alignment: .leading, spacing: 16) {
                CNField {
                    CNFieldLabel("Workspace name")
                    TextField("Name", text: $model.name)
                        .textFieldStyle(.tw("input", state: .init(isFocused: nameFocused)))
                        .focused($nameFocused).onSubmit(model.save)
                }
                Toggle("Notifications", isOn: $model.notifications).toggleStyle(.tw("switch", base: .switch))
                CNCommand(categories, selection: $model.category, query: $model.query, classes: "h-[180]")
                    .itemContent { option, selected in
                        HStack {
                            Label(option.title, systemImage: option.systemImage ?? "folder")
                            Spacer()
                            if selected { CNBadge("Selected") }
                        }
                    } empty: {
                        Label("No categories match your search.", systemImage: "magnifyingglass")
                            .tw("p-4 text-sm text-mutedForeground")
                    }
                Button("Save", action: model.save).buttonStyle(.tw("button-primary")).disabled(!model.canSave)
                Text(model.savedName.isEmpty ? "No saved changes" : "Saved: \(model.savedName)")
                    .tw("text-sm text-mutedForeground")
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .toastContent { context in
            VStack(alignment: .leading, spacing: 8) {
                Text(context.toast.title).tw("text-sm font-semibold")
                if let message = context.toast.message { Text(message).tw("text-sm text-mutedForeground") }
                context.action("Edit name") { nameFocused = true; context.dismiss() }
            }
        }
        .frame(minHeight: 460)
    }
}
