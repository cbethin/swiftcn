import SwiftUI

/// Native text editing. Attach onSubmit, textContentType, and focus modifiers at the call site.
public struct CNInput: View {
    private let title: LocalizedStringKey
    @Binding private var text: String
    private let isSecure: Bool
    private let focus: FocusState<Bool>.Binding?
    private let classes: TWClasses
    @FocusState private var isFocused: Bool
    public init(_ title: LocalizedStringKey, text: Binding<String>, isSecure: Bool = false, focus: FocusState<Bool>.Binding? = nil, classes: TWClasses = "") {
        self.title = title; _text = text; self.isSecure = isSecure; self.focus = focus; self.classes = classes
    }
    public var body: some View {
        Group {
            if isSecure { SecureField(title, text: $text) }
            else { TextField(title, text: $text) }
        }.textFieldStyle(.plain).focused(focus ?? $isFocused)
            .modifier(TWFieldControlModifier(style: .classes(cn("input", classes)), state: .init(isFocused: focus?.wrappedValue ?? isFocused)))
    }
}

public struct CNTextarea: View {
    private let title: String
    @Binding private var text: String
    private let classes: TWClasses
    @FocusState private var isFocused: Bool
    public init(_ title: String, text: Binding<String>, classes: TWClasses = "") {
        self.title = title; _text = text; self.classes = classes
    }
    public var body: some View {
        TextEditor(text: $text).scrollContentBackground(.hidden).focused($isFocused)
            .modifier(TWFieldControlModifier(style: .classes(cn("textarea min-h-[100]", classes)), state: .init(isFocused: isFocused)))
            .accessibilityLabel(title)
    }
}

/// Compose one native input with prefix, suffix, icons, or action buttons.
public struct CNInputGroup<Content: View>: View {
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        self.classes = classes; self.content = content()
    }
    public var body: some View {
        HStack(spacing: 8) { content }.modifier(TWFieldControlModifier(style: .classes(cn("input-group", classes))))
    }
}
public struct CNInputGroupField: View {
    private let title: LocalizedStringKey
    @Binding private var text: String
    public init(_ title: LocalizedStringKey, text: Binding<String>) { self.title = title; _text = text }
    public var body: some View { TextField(title, text: $text).textFieldStyle(.plain).tw("text-sm") }
}

/// One native field supports paste, selection, deletion and one-time-code autofill.
/// It intentionally avoids six independent fields and fragile focus choreography.
public struct CNInputOTP: View {
    @Binding private var code: String
    private let length: Int
    private let classes: TWClasses
    public init(code: Binding<String>, length: Int = 6, classes: TWClasses = "") {
        precondition(length > 0, "Code length must be positive.")
        _code = code; self.length = length; self.classes = classes
    }
    public nonisolated static func normalize(_ value: String, length: Int) -> String {
        String(value.filter { $0.isASCII && $0.isNumber }.prefix(max(0, length)))
    }
    public var body: some View {
        let field = CNInput("Verification code", text: $code, classes: cn("input-otp", classes)).cnTextUtilities()
            .onChange(of: code, initial: true) { _, value in
                let clean = Self.normalize(value, length: length)
                if clean != code { code = clean }
            }
            .accessibilityHint("Enter \(length) digits")
        #if os(iOS)
        field.textContentType(.oneTimeCode).keyboardType(.numberPad)
        #else
        field
        #endif
    }
}
