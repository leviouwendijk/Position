import Testing

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
        Test("legacy-compatibility", tags: ["legacy", "line-endings"]) {
            try test_position_legacy()
            try lineRangeAlgebra()
            try lineRangesCoalesceByGap()
            try fileLineSliceClipsToLoadedSource()
        }
    }
}
