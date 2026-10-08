import SwiftUI

/// Local placement regions for custom controls, popovers, and presentation surfaces.
/// These helpers do not alter navigation or displace continuous scrolling content.
public enum CNPlacementRegions {
    /// Find a division that separates the two panes along their chosen axis.
    public static func divider(in bounds: CGRect, regions: [CGRect], axis: Axis) -> CGRect? {
        regions.compactMap { region -> CGRect? in
            let frame = bounds.intersection(region)
            guard !frame.isNull, frame.width > 0, frame.height > 0 else { return nil }
            let separates = axis == .horizontal ? frame.height >= bounds.height : frame.width >= bounds.width
            return separates ? frame : nil
        }.first
    }

    static func safeBounds(size: CGSize, insets: EdgeInsets, direction: LayoutDirection) -> CGRect {
        let left = direction == .leftToRight ? insets.leading : insets.trailing
        let right = direction == .leftToRight ? insets.trailing : insets.leading
        return CGRect(x: left, y: insets.top, width: max(0, size.width - left - right),
                      height: max(0, size.height - insets.top - insets.bottom))
    }
    /// Produce maximal rectangular candidates that avoid each occupied region.
    public static func available(in bounds: CGRect, avoiding exclusions: [CGRect]) -> [CGRect] {
        guard bounds.width > 0, bounds.height > 0, !bounds.isInfinite, !bounds.isNull else { return [] }
        var candidates = [bounds]
        for exclusion in exclusions where !exclusion.isNull && !exclusion.isInfinite {
            candidates = candidates.flatMap { candidate -> [CGRect] in
                let intersection = candidate.intersection(exclusion)
                guard !intersection.isNull, intersection.width > 0, intersection.height > 0 else { return [candidate] }
                return [
                    CGRect(x: candidate.minX, y: candidate.minY, width: candidate.width, height: intersection.minY - candidate.minY),
                    CGRect(x: candidate.minX, y: intersection.maxY, width: candidate.width, height: candidate.maxY - intersection.maxY),
                    CGRect(x: candidate.minX, y: candidate.minY, width: intersection.minX - candidate.minX, height: candidate.height),
                    CGRect(x: intersection.maxX, y: candidate.minY, width: candidate.maxX - intersection.maxX, height: candidate.height)
                ].filter { $0.width > 0 && $0.height > 0 }
            }
            var unique: [CGRect] = []
            for candidate in candidates where !unique.contains(candidate) { unique.append(candidate) }
            candidates = unique.filter { candidate in !unique.contains { $0 != candidate && $0.contains(candidate) } }
        }
        return candidates
    }

    /// Keep placement near its trigger or preferred corner, using the largest matching region.
    public static func preferred(in regions: [CGRect], near point: CGPoint) -> CGRect {
        regions.min { lhs, rhs in
            let left = distance(from: point, to: lhs), right = distance(from: point, to: rhs)
            if left != right { return left < right }
            return lhs.width * lhs.height > rhs.width * rhs.height
        } ?? .zero
    }

    private static func distance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let dx = max(rect.minX - point.x, 0, point.x - rect.maxX)
        let dy = max(rect.minY - point.y, 0, point.y - rect.maxY)
        return dx * dx + dy * dy
    }
}

extension GeometryProxy {
    /// Active division regions are distinct from small camera occlusions.
    public var cnDivisionRegions: [CGRect] {
        #if os(iOS) && canImport(SwiftUI, _version: 8.0.85.27)
        if #available(iOS 27.1, *) { return reservedRegions(kind: .division, layoutDirectionBehavior: .fixed).map(\.frame) }
        #endif
        return []
    }
    /// Query this view's bounds, safe area, and native reserved regions on supported systems.
    public func cnPlacementRegions(layoutDirection: LayoutDirection) -> [CGRect] {
        cnPlacementRegions(layoutDirection: layoutDirection, insets: safeAreaInsets)
    }
    /// Use enclosing insets when this reader spans the complete host, including the safe area.
    public func cnPlacementRegions(layoutDirection: LayoutDirection, insets: EdgeInsets) -> [CGRect] {
        let bounds = CNPlacementRegions.safeBounds(size: size, insets: insets, direction: layoutDirection)
        // Xcode 27.1 exports these symbols in SwiftUI 8.0.85.27. Older SDKs compile the fallback.
        #if os(iOS) && canImport(SwiftUI, _version: 8.0.85.27)
        if #available(iOS 27.1, *) {
            return CNPlacementRegions.available(in: bounds, avoiding:
                reservedRegions(kind: .division, layoutDirectionBehavior: .fixed).map(\.frame) + reservedRegions(kind: .occlusion, layoutDirectionBehavior: .fixed).map(\.frame))
        }
        #endif
        return CNPlacementRegions.available(in: bounds, avoiding: [])
    }
}
