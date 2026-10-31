import Foundation
import Position
import Schema
import Testing

func test_position_schema() throws {
    typealias Coord = Position.Coordinate<Position.Unit.UTF16>
    let original = try Coord(line: 2, column: 5)
    let bytes = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(Coord.self, from: bytes)
    try expect(decoded == original, "Typed coordinate Codable round-trip")
    try expect((try? JSONDecoder().decode(Coord.self, from: Data(#"{"line":0,"column":1}"#.utf8))) == nil, "Invalid typed coordinate JSON rejected")

    let range = try Position.CoordinateRange(start: original, end: original)
    let rangeBytes = try JSONEncoder().encode(range)
    let decodedRange = try JSONDecoder().decode(Position.CoordinateRange<Position.Unit.UTF16>.self, from: rangeBytes)
    try expect(decodedRange == range, "Typed half-open range Codable round-trip")

    switch Coord.jsonschema.form {
    case .object(let properties, _):
        try expect(properties.contains { $0.name == "line" && $0.required }, "Line schema required")
        try expect(properties.contains { $0.name == "column" && $0.required }, "Column schema required")
    default:
        try expect(false, "Coordinate schema must be an object")
    }

    switch Position.CoordinateRange<Position.Unit.UTF16>.jsonschema.form {
    case .object(let properties, _):
        try expect(properties.contains { $0.name == "start" && $0.required }, "Range start required")
        try expect(properties.contains { $0.name == "end" && $0.required }, "Range end required")
    default:
        try expect(false, "Range schema must be an object")
    }
}

func test_position_legacy() throws {
    let legacy = Position(uncheckedFile: "File.swift", line: 2, column: 3)
    let data = try JSONEncoder().encode(legacy)
    let decoded = try JSONDecoder().decode(Position.self, from: data)
    try expect(decoded == legacy, "Legacy Position Codable unchanged")
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    try expect(object?["line"] as? Int == 2 && object?["column"] as? Int == 3, "Legacy JSON field names retained")

    let crlf = LineTable(text: "a\r\nb")
    let atB = crlf.position(at: PositionIndex(2))
    try expect(atB.line == 2 && atB.column == 1, "CRLF recognized as one Character newline")
    let cr = LineTable(text: "a\rb")
    let atB2 = cr.position(at: PositionIndex(2))
    try expect(atB2.line == 2 && atB2.column == 1, "Standalone CR recognized")
}
