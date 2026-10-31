import Foundation
import Position
import Testing

func test_coordinate_conversions() throws {
    let source = "A𝄞B\r\ne\u{301}\n\tBeta()\rZ"
    let map = Position.TextMap(source: source)
    typealias UTF8 = Position.Unit.UTF8
    typealias UTF16 = Position.Unit.UTF16
    typealias UTF32 = Position.Unit.UTF32
    typealias Grapheme = Position.Unit.Character

    let afterSymbol = try Position.Coordinate<UTF16>(line: 1, column: 4)
    try expect(try map.utf8Offset(at: afterSymbol).offset == 5, "Non-BMP scalar uses 2 UTF-16 units and 4 UTF-8 bytes")
    try expect(try map.convert(afterSymbol, to: UTF8.self).column == 6, "Typed column conversion")
    try expect(try map.convert(afterSymbol, to: UTF32.self).column == 3, "Unicode scalar column")

    let lineTwo = try Position.Coordinate<UTF16>(line: 2, column: 1)
    try expect(try map.utf8Offset(at: lineTwo).offset == 8, "CRLF counts two bytes and one logical newline")
    let lineThree = try Position.Coordinate<UTF16>(line: 3, column: 1)
    try expect(try map.utf8Offset(at: lineThree).offset == 12, "LF line start")
    let lineFour = try Position.Coordinate<UTF16>(line: 4, column: 1)
    try expect(try map.utf8Offset(at: lineFour).offset == 20, "CR line start")

    let combiningEnd = try Position.Coordinate<UTF32>(line: 2, column: 3)
    try expect(try map.convert(combiningEnd, to: Grapheme.self).column == 2, "Combining pair counts as one Character")
    let afterCombining = try map.offset(at: combiningEnd)
    try expect(try map.coordinate(at: afterCombining) == combiningEnd, "UTF-32 round-trip")

    let start = try Position.Coordinate<UTF16>(line: 1, column: 2)
    let end = try Position.Coordinate<UTF16>(line: 1, column: 4)
    let range = try Position.CoordinateRange(start: start, end: end)
    try expect(try map.utf8Range(of: range) == 1..<5, "Half-open UTF-16 range becomes exact UTF-8 bytes")
    let mapped = try map.convert(range, to: UTF8.self)
    try expect(mapped.start.column == 2 && mapped.end.column == 6, "Half-open coordinate range")

    let empty = Position.TextMap(source: "")
    try expect(try empty.utf8Offset(at: .init(line: 1, column: 1)).offset == 0, "Empty file has one EOF point")
    let eof = try map.offset(at: Position.Coordinate<UTF16>(line: 4, column: 2))
    try expect(try map.coordinate(at: eof).line == 4, "EOF is addressable")
}

func test_invalid_boundaries() throws {
    let map = Position.TextMap(source: "A𝄞B\r\ne\u{301}")
    typealias UTF16 = Position.Unit.UTF16
    typealias UTF8 = Position.Unit.UTF8
    typealias Grapheme = Position.Unit.Character

    try expect((try? Position.Coordinate<UTF16>(line: 0, column: 1)) == nil, "Zero line rejected")
    try expect((try? Position.Coordinate<UTF16>(line: 1, column: 0)) == nil, "Zero column rejected")
    try expect((try? Position.Offset<UTF8>(-1)) == nil, "Negative offset rejected")
    try expect((try? map.utf8Offset(at: .init(line: 1, column: 3))) == nil, "Inside surrogate pair rejected")
    try expect((try? map.coordinate(at: Position.Offset<UTF8>(2))) == nil, "Inside UTF-8 multibyte scalar rejected")
    try expect((try? map.coordinate(at: Position.Offset<UTF8>(7))) == nil, "Inside CRLF rejected")
    try expect((try? map.utf8Offset(at: .init(line: 9, column: 1))) == nil, "Missing line rejected")
    try expect((try? map.utf8Offset(at: .init(line: 1, column: 20))) == nil, "Column past end rejected")

    let scalarInterior = try Position.Coordinate<UTF16>(line: 2, column: 2)
    try expect((try? map.convert(scalarInterior, to: Grapheme.self)) == nil, "Interior of grapheme rejected")
    let later = try Position.Coordinate<UTF16>(line: 2, column: 2)
    let earlier = try Position.Coordinate<UTF16>(line: 1, column: 1)
    try expect((try? Position.CoordinateRange(start: later, end: earlier)) == nil, "Reversed range rejected")
}
