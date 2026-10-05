/// Compose typed class values without flattening their interpolation payloads.
public func cn(_ classes: TWClasses?...) -> TWClasses { cn(classes) }

public func cn(_ classes: [TWClasses?]) -> TWClasses {
    var parts: [TWClassPart] = []
    for classes in classes.compactMap({ $0 }) {
        if !parts.isEmpty { parts.append(.literal(" ")) }
        parts.append(contentsOf: classes.parts)
    }
    return TWClasses(parts: parts)
}

/// Runtime String arrays already contain text. The builder also accepts individual String variables.
@_disfavoredOverload
public func cn(_ classes: [String?]) -> TWClasses { cn(classes.map { $0.map { TWClasses($0) } }) }

public func cn(@TWClassBuilder _ classes: () -> [TWClasses]) -> TWClasses { cn(classes()) }

@resultBuilder public enum TWClassBuilder {
    public static func buildExpression(_ value: TWClasses?) -> [TWClasses] { value.map { [$0] } ?? [] }
    @_disfavoredOverload
    public static func buildExpression(_ value: String?) -> [TWClasses] { value.map { [TWClasses($0)] } ?? [] }
    public static func buildExpression(_ values: [TWClasses?]) -> [TWClasses] { values.compactMap { $0 } }
    @_disfavoredOverload
    public static func buildExpression(_ values: [String?]) -> [TWClasses] { values.compactMap { $0.map { TWClasses($0) } } }
    public static func buildBlock(_ values: [TWClasses]...) -> [TWClasses] { values.flatMap { $0 } }
    public static func buildOptional(_ value: [TWClasses]?) -> [TWClasses] { value ?? [] }
    public static func buildEither(first value: [TWClasses]) -> [TWClasses] { value }
    public static func buildEither(second value: [TWClasses]) -> [TWClasses] { value }
    public static func buildArray(_ values: [[TWClasses]]) -> [TWClasses] { values.flatMap { $0 } }
    public static func buildLimitedAvailability(_ value: [TWClasses]) -> [TWClasses] { value }
}
