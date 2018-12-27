//
//  Flattened.swift
//  BlueSteel
//
//  Created by Michael Radtke on 16.01.18.
//  Copyright © 2018 Gilt Groupe. All rights reserved.
//

import Foundation

/// A factory to create primitive - schema- and dataless - `Flattened` values that stand for themselves
public class PrimitiveFlatteningFactory {
	
	public enum ExtractionFailure: Error {
		case unsupportedSchemaId, unsupportedSchemaVersion, unawaitedContent
	}
	
	public let schemaId: UInt16
	public let schemaVersion: UInt8
	
	public init(schemaId: UInt16, schemaVersion: UInt8) {
		self.schemaId = schemaId
		self.schemaVersion = schemaVersion
	}
	
	public var created: Flattened {
		return Flattened(schemaId: schemaId, schemaVersion: schemaVersion)
	}
	
	public func extract(_ flattened: Flattened) throws -> Void {
		guard self.schemaId == flattened.schemaId else {
			throw ExtractionFailure.unsupportedSchemaId
		}
		guard self.schemaVersion == flattened.schemaVersion else {
			throw ExtractionFailure.unsupportedSchemaVersion
		}
		guard flattened.content.isEmpty else {
			throw ExtractionFailure.unawaitedContent
		}
	}
}

/// A factory to create `Flattened` values that contain some data
public class FlatteningFactory {
	
	public enum CreationFailure: Error {
		case invalidSchema
	}
	public enum ExtractionFailure: Error {
		case unsupportedSchemaId, unsupportedSchemaVersion, missingContent, mismatchingContent
	}
	
	public let schemaId: UInt16
	public let schemaVersion: UInt8
	public let schema: Schema
	
	public init(schemaId: UInt16, schemaVersion: UInt8, schema: Schema) {
		self.schemaId = schemaId
		self.schemaVersion = schemaVersion
		self.schema = schema
	}
	
	public init(schemaId: UInt16, schemaVersion: UInt8, schema: String) throws {
		if let theSchema = Schema(schema) {
			self.schemaId = schemaId
			self.schemaVersion = schemaVersion
			self.schema = theSchema
		} else {
			throw CreationFailure.invalidSchema
		}
	}
	
	public func create(_ content: AvroValue) -> Flattened {
		guard let serialized = content.encode(schema) else {
			fatalError("There was a failure while encoding (\(schemaId)-\(schemaVersion)):: AVROVALUE: \(content) <-> SCHEMA: \(schema)")
		}
		return Flattened(schemaId: schemaId, schemaVersion: schemaVersion, content: serialized)
	}
	
	public func extract(_ container: Flattened) throws -> AvroValue {
		guard self.schemaId == container.schemaId else {
			throw ExtractionFailure.unsupportedSchemaId
		}
		guard self.schemaVersion == container.schemaVersion else {
			throw ExtractionFailure.unsupportedSchemaVersion
		}
		guard !container.content.isEmpty else {
			throw ExtractionFailure.missingContent
		}
		
		let avroValue = AvroValue(schema: schema, withBytes: container.content)
		switch avroValue {
		case .avroInvalidValue: throw ExtractionFailure.mismatchingContent
		default: return avroValue
		}
	}
}

/// A Flattened value
public struct Flattened: Hashable {
	
	public let schemaId: UInt16
	public let schemaVersion: UInt8
	public let content: [UInt8]
	
	fileprivate init(schemaId : UInt16, schemaVersion: UInt8, content:[UInt8]? = nil) {
		self.schemaId = schemaId
		self.schemaVersion = schemaVersion
		if let content = content {
			self.content = content
		} else {
			self.content = [UInt8]()
		}
	}
	
	public init?(_ binaryBuffer: [UInt8]) {
		guard binaryBuffer.count >= 3 else {
			return nil
		}

		self.schemaId = (UInt16(binaryBuffer[0]) << 8) + UInt16(binaryBuffer[1])
		self.schemaVersion = binaryBuffer[2]
		self.content = Array(binaryBuffer.dropFirst(3))
	}
	
	public init?(_ data: Data) {
		self.init(data.map{$0})
	}
	
	public var binaryBuffer: [UInt8] {
		return [UInt8(schemaId >> 8), UInt8(schemaId & 0x00FF), schemaVersion] + content
	}
	
	public var data: Data {
		return Data(binaryBuffer)
	}
}


// MARK: - Extension to deal with AvroValue
extension Flattened : AvroValueConvertible {
	
	@available(*, deprecated: 2.0.2, message: "Don't use this anymore!")
	public func avroValueUsing(_ schema: Schema) -> AvroValue? {
		guard !content.isEmpty else {
			return nil
		}
		
		return AvroValue(schema: schema, withBytes: content)
	}
	
	public init?(_ avroValue: AvroValue?) {
		guard
			let bytes = avroValue?.bytes
			else {
				return nil
		}
		
		self.init(bytes)
	}
	
	public func toAvro() -> AvroValue {
		return AvroValue.avroBytesValue(binaryBuffer)
	}
}
