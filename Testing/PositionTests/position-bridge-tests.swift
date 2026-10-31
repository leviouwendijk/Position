import Foundation
import Position
import Testing

func test_position_bridges() throws {
    typealias UTF8 = Position.Unit.UTF8
    typealias UTF16 = Position.Unit.UTF16
    typealias UTF32 = Position.Unit.UTF32
    typealias CharacterUnit = Position.Unit.Character

    let source = "A𝄞B\r\ne\u{301}\n\tBeta()\rZ"
    let map = Position.TextMap(source: source)
    let originalIndex = PositionIndex(2)
    let byteOffset = try map.offset(at: originalIndex, as: UTF8.self)
    try expect(byteOffset.offset == 5, "Character index resolves to UTF-8 byte offset")
    let restoredIndex = try map.index(at: byteOffset)
    try expect(restoredIndex == originalIndex, "Legacy index round-trip")

    let originalRange = try PositionRange(1, 2)
    let typedRange = try map.range(originalRange, as: UTF8.self)
    try expect(
        typedRange.lowerBound.offset == 1 && typedRange.upperBound.offset == 5,
        "Character range converts to UTF-8 byte range"
    )
    let restoredRange = try map.legacyRange(typedRange)
    try expect(restoredRange == originalRange, "Legacy half-open range round-trip")
    let utf16Range = try map.convert(typedRange, to: UTF16.self)
    try expect(
        utf16Range.lowerBound.offset == 1 && utf16Range.upperBound.offset == 3,
        "Typed absolute offset ranges convert across encodings"
    )

    let metadata = InvocationCallSite.function("call")
    let legacy = try Position(file: "File.swift", line: 1, column: 4, invocation: metadata)
    let typed = try map.coordinate(of: legacy, interpretingColumnsAs: UTF16.self)
    let restoredPosition = try map.position(at: typed, file: legacy.file, invocation: legacy.invocation)
    try expect(restoredPosition == legacy, "Metadata-aware Position bridge round-trip")
    let legacyOffset = try map.offset(at: legacy, interpretingColumnsAs: UTF16.self)
    try expect(legacyOffset.offset == 3, "Legacy Position is interpreted in the explicitly specified unit")

    let invalidPosition = Position(uncheckedFile: nil, line: 1, column: 3)
    try expect(
        (try? map.coordinate(of: invalidPosition, interpretingColumnsAs: UTF16.self)) == nil,
        "Legacy position at UTF-16 surrogate interior is rejected"
    )
    let scalarInterior = try Position.Offset<UTF32>(6)
    try expect(
        (try? map.index(at: scalarInterior)) == nil,
        "Scalar interior to a combining grapheme cannot become a Character index"
    )
    try expect(
        (try? map.offset(at: PositionIndex(-1), as: CharacterUnit.self)) == nil,
        "Negative legacy indices are rejected by strict bridges"
    )
}

func test_position_boundary_matrix() throws {
    typealias UTF8 = Position.Unit.UTF8
    typealias UTF16 = Position.Unit.UTF16
    typealias UTF32 = Position.Unit.UTF32
    typealias CharacterUnit = Position.Unit.Character

    let sources = [
        "",
        "a\n",
        "\r\n\r\n",
        "A𝄞B\r\ne\u{301}\n",
        "👩‍💻🇳🇱\rtext\n",
        "\tλ\r\n\u{301}\n",
    ]

    for source in sources {
        let map = Position.TextMap(source: source)
        for raw in 0...source.utf8.count {
            let candidate = try Position.Offset<UTF8>(raw)
            guard let utf16 = try? map.convert(candidate, to: UTF16.self) else {
                continue
            }
            let utf8RoundTrip = try map.convert(utf16, to: UTF8.self)
            try expect(utf8RoundTrip == candidate, "UTF-8/UTF-16 valid-boundary round-trip")

            let utf32 = try map.convert(candidate, to: UTF32.self)
            let scalarRoundTrip = try map.convert(utf32, to: UTF8.self)
            try expect(scalarRoundTrip == candidate, "UTF-8/UTF-32 valid-boundary round-trip")

            if let characters = try? map.convert(candidate, to: CharacterUnit.self) {
                let characterRoundTrip = try map.convert(characters, to: UTF8.self)
                try expect(characterRoundTrip == candidate, "UTF-8/Character valid-boundary round-trip")
            }
        }
    }
}

func test_position_large_source() throws {
    typealias UTF16 = Position.Unit.UTF16
    let source = String(repeating: "line α\r\n", count: 10_000) + "END"
    let map = Position.TextMap(source: source)
    let cursor = try Position.Coordinate<UTF16>(line: 10_001, column: 4)
    let eof = try map.utf8Offset(at: cursor)
    try expect(eof.offset == source.utf8.count, "Last line in large document resolves to EOF")

    let back = try map.coordinate(at: try Position.Offset<Position.Unit.UTF8>(eof.offset))
    try expect(back.line == 10_001 && back.column == 4, "Large-source offset resolves to correct line")
}
