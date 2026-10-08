import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Reserved placement regions")
struct PlacementRegionTests {
    @Test func dividerPlacementRestoresTheSavedFractionAndMirrorsPanes() {
        let size = CGSize(width: 800, height: 600)
        let fold = CGRect(x: 300, y: 0, width: 20, height: 600)
        let folded = CNResizePlacement(size: size, divisions: [fold], axis: .horizontal,
                                       direction: .leftToRight, fraction: 0.35, handleExtent: 44)
        #expect(folded.first == 300 && folded.handle == 20 && folded.length - folded.first == 480)
        let rtl = CNResizePlacement(size: size, divisions: [fold], axis: .horizontal,
                                   direction: .rightToLeft, fraction: 0.35, handleExtent: 44)
        #expect(rtl.first == 480 && rtl.length - rtl.first == 300)
        let flat = CNResizePlacement(size: size, divisions: [], axis: .horizontal,
                                    direction: .leftToRight, fraction: 0.35, handleExtent: 44)
        #expect(abs(flat.first - 756 * 0.35) < 0.001 && flat.handle == 44 && !flat.divided)
        let dragged = CNResizePlacement(size: size, divisions: [], axis: .horizontal,
                                       direction: .leftToRight, fraction: 0.4, handleExtent: 44)
        #expect(flat.divisionStart == dragged.divisionStart && flat.handle == dragged.handle,
                "Ordinary binding updates must not invalidate a divider grab.")
    }
    @Test func popoverEdgesMirrorWithinPhysicalPlacementBounds() {
        let bounds = CGRect(x: 410, y: 30, width: 370, height: 540)
        let anchor = CGRect(x: 570, y: 100, width: 40, height: 44)
        let popup = CGSize(width: 120, height: 80)
        #expect(CNPopoverPosition.origin(anchor: anchor, popup: popup, bounds: bounds, edge: .leading).x == 616)
        #expect(CNPopoverPosition.origin(anchor: anchor, popup: popup, bounds: bounds, edge: .leading, direction: .rightToLeft).x == 444)
    }
    @Test func safeBoundsUsePhysicalInsetsInBothDirections() {
        let size = CGSize(width: 800, height: 600)
        let insets = EdgeInsets(top: 12, leading: 24, bottom: 20, trailing: 60)
        #expect(CNPlacementRegions.safeBounds(size: size, insets: insets, direction: .leftToRight) == CGRect(x: 24, y: 12, width: 716, height: 568))
        #expect(CNPlacementRegions.safeBounds(size: size, insets: insets, direction: .rightToLeft) == CGRect(x: 60, y: 12, width: 716, height: 568))
    }
    @Test func onlyActiveFullSpanDivisionsReplaceTheResizeHandle() {
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
        let vertical = CGRect(x: 390, y: 0, width: 20, height: 600)
        let horizontal = CGRect(x: 0, y: 290, width: 800, height: 20)
        let camera = CGRect(x: 710, y: 0, width: 70, height: 50)
        #expect(CNPlacementRegions.divider(in: bounds, regions: [camera, vertical], axis: .horizontal) == vertical)
        #expect(CNPlacementRegions.divider(in: bounds, regions: [horizontal], axis: .vertical) == horizontal)
        #expect(CNPlacementRegions.divider(in: bounds, regions: [vertical], axis: .vertical) == nil)
        #expect(CNPlacementRegions.divider(in: bounds, regions: [CGRect(x: 400, y: 0, width: 0, height: 600)], axis: .horizontal) == nil)
    }
    @Test func verticalFoldKeepsAnchoredControlsOnTheirSide() {
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
        let hinge = CGRect(x: 390, y: 0, width: 20, height: 600)
        let regions = CNPlacementRegions.available(in: bounds, avoiding: [hinge])
        #expect(regions.count == 2)
        #expect(CNPlacementRegions.preferred(in: regions, near: CGPoint(x: 100, y: 100)) == CGRect(x: 0, y: 0, width: 390, height: 600))
        #expect(CNPlacementRegions.preferred(in: regions, near: CGPoint(x: 800, y: 600)) == CGRect(x: 410, y: 0, width: 390, height: 600))
    }
    @Test func tabletopFoldKeepsBottomControlsBelowTheFold() {
        let bounds = CGRect(x: 0, y: 0, width: 600, height: 800)
        let hinge = CGRect(x: 0, y: 390, width: 600, height: 20)
        let regions = CNPlacementRegions.available(in: bounds, avoiding: [hinge])
        #expect(CNPlacementRegions.preferred(in: regions, near: CGPoint(x: 600, y: 800)) == CGRect(x: 0, y: 410, width: 600, height: 390))
    }
    @Test func cameraAndFoldCandidatesNeverCoverEitherReservedRegion() {
        let bounds = CGRect(x: 20, y: 30, width: 760, height: 540)
        let exclusions = [CGRect(x: 390, y: 0, width: 20, height: 600), CGRect(x: 710, y: 30, width: 70, height: 50)]
        let regions = CNPlacementRegions.available(in: bounds, avoiding: exclusions)
        for region in regions {
            #expect(bounds.contains(region))
            for exclusion in exclusions {
                let intersection = region.intersection(exclusion)
                #expect(intersection.isNull || intersection.width == 0 || intersection.height == 0)
            }
        }
        #expect(CNPlacementRegions.preferred(in: regions, near: CGPoint(x: 780, y: 570)).width == 370)
    }
    @Test func inactiveFoldsAndExternalRegionsDoNotChangePlacement() {
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
        #expect(CNPlacementRegions.available(in: bounds, avoiding: [CGRect(x: 400, y: 0, width: 0, height: 600),
            CGRect(x: 900, y: 0, width: 20, height: 600)]) == [bounds])
        #expect(CNPlacementRegions.available(in: bounds, avoiding: [bounds]).isEmpty)
        #expect(CNPlacementRegions.preferred(in: [], near: .zero) == .zero)
    }
}
