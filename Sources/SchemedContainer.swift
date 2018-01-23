//
//  SchemedContainer.swift
//  BlueSteel
//
//  Created by Michael Radtke on 16.01.18.
//  Copyright © 2018 Gilt Groupe. All rights reserved.
//

import Foundation


public struct SchemedContainerFactory {
	
	public let schemaId: UInt16
	public let schemaVersion: UInt8
	public let schema: Schema?
	
	public init(schemaId: UInt16, schemaVersion: UInt8, schema: Schema? = nil) {
		self.schemaId = schemaId
		self.schemaVersion = schemaVersion
		self.schema = schema
	}
	
	public var create : SchemedContainer {
		guard schema == nil else {
			fatalError("This factory has a schema applied, therefore some data must be given!")
		}
		return SchemedContainer(schemaId: schemaId, schemaVersion: schemaVersion)
	}
	
	public func createFor(_ content: AvroValue) -> SchemedContainer {
		guard let schema = schema else {
			fatalError("This factory is schemaless, therefore no data can be given!")
		}
		guard let serialized = content.encode(schema) else {
			fatalError("")
		}
		return SchemedContainer(schemaId: schemaId, schemaVersion: schemaVersion, content: serialized)
	}
}

public struct SchemedContainer {
	
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


extension SchemedContainer: Equatable {
	
	public static func ==(lhs: SchemedContainer, rhs: SchemedContainer) -> Bool {
		return lhs.schemaId == rhs.schemaId
				&& lhs.schemaVersion == rhs.schemaVersion
				&& lhs.binaryBuffer == rhs.content
	}
}


// MARK: - Extension to deal with AvroValue
extension SchemedContainer : AvroValueConvertible {
	
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
