import Testing
import Position

private enum PositionTestFailure: Error {
    case failed
}

@main
enum PositionTestMain {
    static func main() async throws {
        let reporter = PlainTextTestReporter()
        let result = await TestRunner.run(PositionTestSuite.suite, sink: reporter)
        print(await reporter.rendered())
        if result.isFailure {
            throw PositionTestFailure.failed
        }
    }
}

enum PositionTestSuite {
    static let suite = TestSuite("position", title: "Position coordinate tests") {
        Test("unicode-and-line-endings", tags: ["coordinate", "unicode"]) {
            try test_coordinate_conversions()
        }
        Test("invalid-boundaries", tags: ["coordinate", "validation"]) {
            try test_invalid_boundaries()
        }
        Test("codable-and-schema", tags: ["schema", "coding"]) {
            try test_position_schema()
        }
        Test("legacy-position-bridges", tags: ["legacy", "coordinate"]) {
            try test_position_bridges()
        }
        Test("coordinate-boundary-matrix", tags: ["coordinate", "unicode"]) {
            try test_position_boundary_matrix()
        }
        Test("large-source-coordinates", tags: ["coordinate", "performance"]) {
            try test_position_large_source()
        }
        Test("line-extents", tags: ["line", "range"]) {
            let empty = try LineExtent(start: 1, count: 0)
            guard empty.isEmpty, empty.end == 1, empty.range == nil else {
                throw PositionTestFailure.failed
            }
            let region = try LineExtent(start: 12, count: 3)
            guard region.end == 15, region.contains(14), !region.contains(15),
                  region.range == (try LineRange(12, 14)),
                  region.intersection(try LineExtent(start: 14, count: 3)) == (try LineExtent(start: 14, count: 1)) else {
                throw PositionTestFailure.failed
            }
        }
        Test("legacy-compatibility", tags: ["legacy", "line-endings"]) {
            try test_position_legacy()
            try lineRangeAlgebra()
            try lineRangesCoalesceByGap()
            try fileLineSliceClipsToLoadedSource()
        }
    }
}
