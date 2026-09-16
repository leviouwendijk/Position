import Foundation
import Position

enum RegressionFailure: Error {
    case assertion(String)
}

func expect(
    _ condition: @autoclosure () -> Bool,
    _ message: String
) throws {
    guard condition() else {
        throw RegressionFailure.assertion(
            message
        )
    }
}

func lineRangeAlgebra() throws {
    let first = try LineRange(start: 3, end: 5)
    let adjacent = try LineRange(start: 6, end: 8)
    let separated = try LineRange(start: 10, end: 10)
    let bounds = try LineRange(start: 1, end: 9)
    let adjacentUnion = try LineRange(start: 3, end: 8)
    let separatedUnion = try LineRange(start: 6, end: 10)
    let expanded = try LineRange(start: 1, end: 9)

    try expect(
        first.intersection(adjacent) == nil,
        "adjacent ranges must not intersect"
    )
    try expect(
        first.gap(to: adjacent) == 0,
        "adjacent ranges have zero gap"
    )
    try expect(
        first.union(adjacent) == adjacentUnion,
        "adjacent ranges union"
    )
    try expect(
        adjacent.gap(to: separated) == 1,
        "separated range gap"
    )
    try expect(
        adjacent.union(
            separated,
            maximumGap: 1
        ) == separatedUnion,
        "maximum-gap union"
    )
    try expect(
        first.expanded(
            by: 4,
            within: bounds
        ) == expanded,
        "bounded expansion"
    )
}

func lineRangesCoalesceByGap() throws {
    let oneTwo = try LineRange(start: 1, end: 2)
    let threeFour = try LineRange(start: 3, end: 4)
    let six = try LineRange(start: 6, end: 6)
    let oneFour = try LineRange(start: 1, end: 4)
    let oneSix = try LineRange(start: 1, end: 6)
    let ranges = [
        oneTwo,
        threeFour,
        six,
    ]

    try expect(
        ranges.coalesced() == [
            oneFour,
            six,
        ],
        "default coalescing"
    )
    try expect(
        ranges.coalesced(
            maximumGap: 1
        ) == [
            oneSix,
        ],
        "gap-aware coalescing"
    )
}

func fileLineSliceClipsToLoadedSource() throws {
    let file = URL(
        fileURLWithPath: "/tmp/source.swift"
    )
    let slice = FileLineSlice(
        file: file,
        lines: [
            "one",
            "two",
            "three",
            "four",
        ],
        range: LineRange(
            uncheckedStart: 0,
            uncheckedEnd: 3
        )
    )

    try expect(
        slice?.startLine == 1,
        "slice start clips to first line"
    )
    try expect(
        slice?.lines == [
            "one",
            "two",
            "three",
        ],
        "slice contents clip to source"
    )
}

try lineRangeAlgebra()
try lineRangesCoalesceByGap()
try fileLineSliceClipsToLoadedSource()
print("PositionTests: passed")
