import Schema

// Keep every schema conformance independent of the coordinate machinery.
// Codable owns validation; JSONSchema describes the encoded representation.

extension Position.Coordinate: JSONSchemaProviding {
    public static var jsonschema: JSONSchema {
        .object(
            properties: [
                JSONSchema.integer("line", required: true),
                JSONSchema.integer("column", required: true),
            ],
            additionalProperties: .disallowed
        )
    }
}

extension Position.Offset: JSONSchemaProviding {
    public static var jsonschema: JSONSchema {
        .object(
            properties: [
                JSONSchema.integer("offset", required: true),
            ],
            additionalProperties: .disallowed
        )
    }
}

extension Position.CoordinateRange: JSONSchemaProviding {
    public static var jsonschema: JSONSchema {
        .object(
            properties: [
                JSONSchema.property("start", schema: Position.Coordinate<Unit>.jsonschema, required: true),
                JSONSchema.property("end", schema: Position.Coordinate<Unit>.jsonschema, required: true),
            ],
            additionalProperties: .disallowed
        )
    }
}

extension PositionIndex: JSONSchemaProviding {
    public static var jsonschema: JSONSchema {
        .object(
            properties: [
                JSONSchema.integer("offset", required: true),
            ],
            additionalProperties: .allowed
        )
    }
}

extension PositionRange: JSONSchemaProviding {
    public static var jsonschema: JSONSchema {
        .object(
            properties: [
                JSONSchema.property("start", schema: PositionIndex.jsonschema, required: true),
                JSONSchema.property("end", schema: PositionIndex.jsonschema, required: true),
            ],
            additionalProperties: .allowed
        )
    }
}

extension LineRange: JSONSchemaProviding {
    public static var jsonschema: JSONSchema {
        .object(
            properties: [
                JSONSchema.integer("start", required: true),
                JSONSchema.integer("end", required: true),
            ],
            additionalProperties: .allowed
        )
    }
}

extension InvocationCallSiteType: JSONSchemaProviding {
    public static var jsonschema: JSONSchema {
        .string(cases: ["structure", "function", "enumeration"])
    }
}

extension InvocationCallSite: JSONSchemaProviding {
    public static var jsonschema: JSONSchema {
        .object(
            properties: [
                JSONSchema.property("file", schema: String?.jsonschema),
                JSONSchema.property("type", schema: InvocationCallSiteType?.jsonschema),
                JSONSchema.property("scope", schema: String?.jsonschema),
            ],
            additionalProperties: .allowed
        )
    }
}

extension Position: JSONSchemaProviding {
    public static var jsonschema: JSONSchema {
        .object(
            properties: [
                JSONSchema.property("file", schema: String?.jsonschema),
                JSONSchema.integer("line", required: true),
                JSONSchema.integer("column", required: true),
                JSONSchema.property("invocation", schema: InvocationCallSite?.jsonschema),
            ],
            additionalProperties: .allowed
        )
    }
}

extension PositionSpan: JSONSchemaProviding {
    public static var jsonschema: JSONSchema {
        .object(
            properties: [
                JSONSchema.property("start", schema: Position.jsonschema, required: true),
                JSONSchema.property("end", schema: Position.jsonschema, required: true),
            ],
            additionalProperties: .allowed
        )
    }
}
