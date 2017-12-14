//
//  ObjectDescription.swift
//  BlueSteel
//
//  Created by Michael Radtke on 14.12.17.
//  Copyright © 2017 Gilt Groupe. All rights reserved.
//

import Foundation

public protocol TypeRepresentation {
	var jsonString: String {get}
}

public class SchemaDescriptor {
	private let objectName: String
	private let attributes: [Attribute]
	
	private var _jsonString: String?
	private var _schema: Schema?
	
	
	public enum Primitive: String, TypeRepresentation {
		case boolean 	= "boolean"
		case int		= "int"
		case long		= "long"
		case float		= "float"
		case double		= "double"
		case bytes		= "bytes"
		case string		= "string"
		
		public var jsonString: String {
			return "\"\(self.rawValue)\""
		}
	}
	
	public struct ArrayOf: TypeRepresentation {
		private let type: StringRepresentation
		
		public init(_ type: SchemaDescriptor) {
			self.type = StringRepresentation(type.jsonRepresentation)
		}
		
		public init(_ primitve: SchemaDescriptor.Primitive) {
			self.type = StringRepresentation(primitve.rawValue)
		}
		
		public var jsonString: String {
			return "{\"type\":\"array\",\"items\":\(type.jsonString)}"
		}
	}
	
	public struct From: TypeRepresentation {
		private let type: StringRepresentation
		
		public init(_ objectDescription: SchemaDescriptor) {
			self.type = StringRepresentation(objectDescription.jsonRepresentation)
		}
		
		public var jsonString: String {
			return type.jsonString
		}
	}
	
	private struct StringRepresentation: TypeRepresentation {
		let type: String
		
		init(_ type: String) {
			self.type = type
		}
		
		var jsonString: String {
			if type.starts(with: "{") {
				return type
			}
			return "\"\(type)\""
		}
	}
	
	public struct Attribute {
		private let name: StringRepresentation
		private let type: TypeRepresentation
		
		public init(name: String, type: TypeRepresentation) {
			self.name = StringRepresentation(name)
			self.type = type
		}
		
		var json: String {
			return "{\"name\":\(name.jsonString),\"type\":\(type.jsonString)}"
		}
		
		public var fieldName: String {
			return name.type
		}
	}
	
	public init(objectName: String, attributes: Attribute...) {
		self.objectName = objectName
		self.attributes = attributes
	}
	
	public var jsonRepresentation: String {
		if _jsonString == nil {
			let opening = "{\"name\":\"\(objectName)\",\"type\":\"record\",\"fields\":["
			let closing = "]}"
			
			let content = attributes.reduce("") { $0 + ($0.isEmpty ? "" : ",") + $1.json}
			
			_jsonString = opening + content + closing
		}
		return _jsonString!
	}
	
	public var schema: Schema {
		if _schema == nil {
			guard let schema = Schema(jsonRepresentation) else {
				fatalError()
			}
			_schema = schema
		}
		return _schema!
	}
}

// Extend AvroValue to enable directly working with Object Descriptor
extension AvroValue {
	public init(objectDescription: SchemaDescriptor, withData data: Data) {
		self.init(schema: objectDescription.schema, withData: data)
	}
	
	public init(objectDescription: SchemaDescriptor, withData data: [UInt8]) {
		self.init(schema: objectDescription.schema, withBytes: data)
	}
	
	public func encode(_ objectDescription: SchemaDescriptor) -> [UInt8]? {
		return encode(objectDescription.schema)
	}
}

