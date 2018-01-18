//
//  SmallSchemed.swift
//  BlueSteel
//
//  Created by Michael Radtke on 16.01.18.
//  Copyright © 2018 Gilt Groupe. All rights reserved.
//

import Foundation


public struct SendingSchemedContainer {
	private let schemaId: UInt16
	private let schemaVersion: UInt8
	private let schema: Schema?
	
	public init(schemaId: UInt16, schemaVersion: UInt8, schema: Schema? = nil) {
		self.schemaId = schemaId
		self.schemaVersion = schemaVersion
		self.schema = schema
	}
	
	public var serialized : Data {
		guard schema == nil else {
			fatalError("Data must be given when a schema is present")
		}
		return Data(schemaInformation())
	}
	
	public func serializedFor(_ content: AvroValue) -> Data {
		guard schema != nil else {
			fatalError("A Schema must be given when avroValue should be serialized")
		}
		return Data(schemaInformation() + content.encode(schema!)!)
	}
	
	private func schemaInformation() -> [UInt8] {
		return [UInt8(schemaId >> 8), UInt8(schemaId & 0x00FF), schemaVersion]
	}
}

public struct ReceivingSchemedContainer {
	public let schemaId: UInt16
	public let schemaVersion: UInt8
	public let serializedContent: [UInt8]
	
	public init?(binaryBuffer: [UInt8]) {
		guard binaryBuffer.count >= 3 else {
			return nil
		}

		self.schemaId = (UInt16(binaryBuffer[0]) << 8) + UInt16(binaryBuffer[1])
		self.schemaVersion = binaryBuffer[2]
		self.serializedContent = Array(binaryBuffer.dropFirst(3))
	}
	
	public init?(data: Data) {
		self.init(binaryBuffer: data.map{$0})
	}
}
