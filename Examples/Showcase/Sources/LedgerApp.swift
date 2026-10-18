import SwiftUI
import Charts
import SwiftCN

struct LedgerApp: View {
    @Bindable var store: ShowcaseStore
    let exit: () -> Void
    @State private var adding = false
    @State private var addingFromActivity = false
    @State private var detailEditing: Expense?
    @State private var editing: Expense?
    @State private var category = "All"
    @State private var budgetEditor = false
    @State private var selectedExpense: UUID?
    @Environment(\.horizontalSizeClass) private var sizeClass
    private let categories = ["Food", "Travel", "Life"]
    var body: some View {
        TabView {
            NavigationStack {
                Page {
                    PageHeading(eyebrow: "Your money, at ease", title: "Know where\nyou stand.", subtitle: "A clearer view of the everyday.")
                    Surface(classes: "bg-primary border-0") {
                        Text("AVAILABLE TO SPEND").tracking(1.5).tw("text-xs text-onPrimary opacity-80")
                        Text(money(store.data.budgetCents - store.spentCents)).font(.system(size: 44, weight: .medium, design: .rounded))
                            .minimumScaleFactor(0.6).lineLimit(1).tw("text-onPrimary")
                        HStack { Text("Monthly budget"); Spacer(); Text(money(store.data.budgetCents)) }.tw("text-sm text-onPrimary opacity-80")
                    }
                    Surface {
                        SectionHeading(title: "Where it goes", detail: money(store.spentCents))
                        CNChart("h-[180] border-0 p-0") {
                            ForEach(categories, id: \.self) { category in
                                BarMark(x: .value("Category", category), y: .value("Amount", Double(total(category)) / 100))
                                    .foregroundStyle(DemoApp.ledger.accent.gradient).cornerRadius(6)
                            }
                        }.chartYAxis(.hidden)
                        ForEach(categories, id: \.self) { category in
                            HStack { Label(category, systemImage: icon(category)); Spacer(); Text(money(total(category))).monospacedDigit() }.tw("text-sm")
                        }
                    }
                    SectionHeading(title: "Latest activity")
                    ForEach(store.data.expenses.prefix(3)) { expense in expenseRow(expense) }
                    CNButton("Add expense", classes: "w-full") { adding = true }.accessibilityIdentifier("add-expense")
                        .sourceSheet(isPresented: $adding) { ExpenseEditor(store: store, expense: nil) }
                }.modifier(DemoToolbar(app: .ledger, exit: exit))
            }.tabItem { Label("Overview", systemImage: "chart.bar.xaxis") }
            // Keep native widths unconstrained so Duo can align both panes with the hinge.
            NavigationSplitView {
                List(selection: $selectedExpense) {
                    VStack(alignment: .leading, spacing: 18) {
                        PageHeading(eyebrow: "The everyday", title: "Every little thing.", subtitle: "Your spending, with the details intact.")
                        Picker("Category", selection: $category) { ForEach(["All"] + categories, id: \.self) { Text($0).tag($0) } }.pickerStyle(.menu)
                        CNButton("Add expense", classes: "w-full") { addingFromActivity = true }
                            .sourceSheet(isPresented: $addingFromActivity) { ExpenseEditor(store: store, expense: nil) }
                    }.collectionRow()
                    let expenses = store.data.expenses.filter { category == "All" || $0.category == category }
                    if expenses.isEmpty { EmptyMessage(symbol: "tray", title: "Nothing here yet", message: "Add your first expense to start seeing the picture.").collectionRow() }
                    ForEach(expenses) { expense in
                        NavigationLink(value: expense.id) { expenseLabel(expense) }.collectionRow()
                    }
                }.collectionStyle().modifier(DemoToolbar(app: .ledger, exit: exit))
            } detail: {
                Page {
                    if let expense = store.data.expenses.first(where: { $0.id == selectedExpense }) {
                        PageHeading(eyebrow: expense.category, title: expense.title, subtitle: expense.date.formatted(date: .long, time: .omitted))
                        Surface(classes: "bg-accent border-0") {
                            Label("Amount", systemImage: icon(expense.category)).tw("text-sm text-primary")
                            Text(money(expense.cents)).font(.system(.largeTitle, design: .rounded)).monospacedDigit().tw("font-semibold")
                            CNButton("Edit expense", variant: .outline) { detailEditing = expense }
                                .sourceSheet(item: $detailEditing) { ExpenseEditor(store: store, expense: $0) }
                        }
                        Surface {
                            SectionHeading(title: "The bigger picture")
                            HStack { Text("\(expense.category) this month"); Spacer(); Text(money(total(expense.category))) }.tw("text-sm")
                            CNProgress("Budget used", value: Double(store.spentCents), total: Double(store.data.budgetCents))
                            Text("\(money(store.data.budgetCents - store.spentCents)) left in your monthly budget.").tw("text-sm text-mutedForeground")
                        }
                    } else { EmptyMessage(symbol: "receipt", title: "A clearer view", message: "Choose a transaction to see its details and place in your budget.") }
                }.navigationTitle("Transaction").navigationBarTitleDisplayMode(.inline)
            }
                .onChange(of: sizeClass, initial: true) { _, value in
                    if value == .regular && selectedExpense == nil { selectedExpense = store.data.expenses.first?.id }
                }
                .onChange(of: store.data.expenses.map(\.id)) { _, ids in
                    if let selectedExpense, !ids.contains(selectedExpense) { self.selectedExpense = nil }
                }
                .tabItem { Label("Activity", systemImage: "list.bullet.rectangle") }
            NavigationStack {
                Page {
                    PageHeading(eyebrow: "A little intention", title: "Make a plan.", subtitle: "A budget is room for what matters.")
                    Surface {
                        SectionHeading(title: "Monthly budget", detail: money(store.data.budgetCents))
                        CNProgress("Budget used", value: Double(store.spentCents), total: Double(store.data.budgetCents))
                        Text("\(money(store.spentCents)) spent so far").tw("text-sm text-mutedForeground")
                        CNButton("Change budget", variant: .outline) { budgetEditor = true }
                            .sourceSheet(isPresented: $budgetEditor) { BudgetEditor(store: store) }
                    }
                    EmptyMessage(symbol: "leaf", title: "Keep it simple", message: "All amounts use USD. No bank connection, no tracking. Just a useful local notebook for your money.")
                }.modifier(DemoToolbar(app: .ledger, exit: exit))
            }.tabItem { Label("Budget", systemImage: "circle.dotted") }
        }
    }
    private func total(_ category: String) -> Int { store.monthlyExpenses.filter { $0.category == category }.reduce(0) { $0 + $1.cents } }
    private func icon(_ category: String) -> String { category == "Food" ? "cup.and.saucer" : category == "Travel" ? "tram" : "sparkles" }
    private func expenseRow(_ expense: Expense) -> some View {
        Button { editing = expense } label: { expenseLabel(expense) }
            .buttonStyle(.plain)
            .sourceSheet(item: Binding(get: { editing?.id == expense.id ? editing : nil }, set: { value in
                if value != nil || editing?.id == expense.id { editing = value }
            })) { ExpenseEditor(store: store, expense: $0) }
    }
    private func expenseLabel(_ expense: Expense) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon(expense.category)).tw("p-3 bg-accent text-primary rounded-[14]")
            VStack(alignment: .leading, spacing: 5) { Text(expense.title).tw("font-medium text-sm text-foreground"); Text(expense.category).tw("text-xs text-mutedForeground") }
            Spacer(minLength: 4)
            Text(money(expense.cents)).monospacedDigit().tw("font-semibold text-sm text-foreground")
        }.tw("p-3 bg-surface rounded-[18] border w-full")
    }

}
private struct ExpenseEditor: View {
    let store: ShowcaseStore
    let expense: Expense?
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var amount: String
    @State private var category: String
    @State private var date: Date
    init(store: ShowcaseStore, expense: Expense?) {
        self.store = store; self.expense = expense
        _title = State(initialValue: expense?.title ?? "")
        _amount = State(initialValue: expense.map { String(format: "%.2f", Double($0.cents) / 100) } ?? "")
        _category = State(initialValue: expense?.category ?? "Food")
        _date = State(initialValue: expense?.date ?? Date())
    }
    var body: some View {
        EditorSheet(title: expense == nil ? "New expense" : "Edit expense", canSave: !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && ShowcaseStore.cents(from: amount) != nil) {
            guard let cents = ShowcaseStore.cents(from: amount), !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
            let saved = Expense(id: expense?.id ?? UUID(), title: title.trimmingCharacters(in: .whitespacesAndNewlines), cents: cents, category: category, date: date)
            if let index = store.data.expenses.firstIndex(where: { $0.id == saved.id }) { store.data.expenses[index] = saved }
            else { store.data.expenses.insert(saved, at: 0) }
            return true
        } content: {
            CNField { CNFieldLabel("What was it?"); CNInput("Expense name", text: $title).accessibilityIdentifier("expense-title") }
            CNField { CNFieldLabel("Amount in USD"); CNInput("0.00", text: $amount).keyboardType(.decimalPad).accessibilityIdentifier("expense-amount") }
            Text("Use a decimal point, for example 12.50.").tw("text-xs text-mutedForeground")
            Picker("Category", selection: $category) { ForEach(["Food", "Travel", "Life"], id: \.self) { Text($0).tag($0) } }.pickerStyle(.segmented)
            CNDatePicker("Date", selection: $date)
            if let expense {
                CNButton("Delete expense", variant: .destructive) { store.data.expenses.removeAll { $0.id == expense.id }; dismiss() }
            }
        }
    }
}
private struct BudgetEditor: View {
    let store: ShowcaseStore
    @State private var amount: String
    init(store: ShowcaseStore) { self.store = store; _amount = State(initialValue: String(format: "%.2f", Double(store.data.budgetCents) / 100)) }
    var body: some View {
        EditorSheet(title: "Monthly budget", canSave: ShowcaseStore.cents(from: amount) != nil) {
            guard let cents = ShowcaseStore.cents(from: amount) else { return false }
            store.data.budgetCents = cents
            return true
        } content: { CNField { CNFieldLabel("Amount in USD"); CNInput("Budget", text: $amount).keyboardType(.decimalPad) } }
    }
}
