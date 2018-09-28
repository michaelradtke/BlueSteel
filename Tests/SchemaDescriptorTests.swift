//
//  ObjectDescriptorTests.swift
//  BlueSteelTests
//
//  Created by Michael Radtke on 14.12.17.
//  Copyright © 2017 Gilt Groupe. All rights reserved.
//

import XCTest
import BlueSteel

class SchemaDescriptorTests: XCTestCase {
	
	struct Child: AvroValueConvertible, Equatable {
		let name: String
		let age: Int
		
		public init(name: String, age: Int) {
			self.name = name
			self.age = age
		}
		
		public static func ==(lhs: Child, rhs: Child) -> Bool {
			return lhs.name == rhs.name && lhs.age == rhs.age
		}
		
		private static let NAME_ATTR = SchemaDescriptor.Attribute(name: "name",
																  type: SchemaDescriptor.Primitive.string
		)
		private static let AGE_ATTR = SchemaDescriptor.Attribute(name: "age",
																 type: SchemaDescriptor.Primitive.long
		)
		
		public static let schemaDescriptor = SchemaDescriptor(objectName: "child",
															  attributes: NAME_ATTR, AGE_ATTR
		)
		
		func toAvro() -> AvroValue {
			return AvroValue.avroRecordValue([
				Child.NAME_ATTR.fieldName: name.toAvro(),
				Child.AGE_ATTR.fieldName: age.toAvro()
				])
		}
		
		public init?(avroValue: AvroValue?) {
			guard let record = avroValue?.record,
				let name = record[Child.NAME_ATTR.fieldName]?.string,
				let age = record[Child.AGE_ATTR.fieldName]?.long
				else {
					return nil
			}
			self.init(name: name, age: Int(age))
		}
	}
	
	struct Parent: AvroValueConvertible, Equatable {
		let name: String
		let children: [Child]
		
		public init(name: String, children: [Child]) {
			self.name = name
			self.children = children
		}
		
		public static func ==(lhs: Parent, rhs: Parent) -> Bool {
			return lhs.name == rhs.name && lhs.children == rhs.children
		}
		
		private static let NAME_ATTR = SchemaDescriptor.Attribute(name: "name",
																  type: SchemaDescriptor.Primitive.string
		)
		private static let CHILDREN_ATTR = SchemaDescriptor.Attribute(name: "children",
																	  type: SchemaDescriptor.ArrayOf(Child.schemaDescriptor)
		)
		
		public static let schemaDescriptor = SchemaDescriptor(objectName: "parent",
															  attributes: Parent.NAME_ATTR, Parent.CHILDREN_ATTR
		)
		
		func toAvro() -> AvroValue {
			return AvroValue.avroRecordValue([
				Parent.NAME_ATTR.fieldName: name.toAvro(),
				Parent.CHILDREN_ATTR.fieldName: AvroValue.avroArrayValue(children.map{$0.toAvro()})
				])
		}
		
		public init?(avroValue: AvroValue?) {
			guard let record = avroValue?.record,
				let name = record[Parent.NAME_ATTR.fieldName]?.string,
				let childlist = record[Parent.CHILDREN_ATTR.fieldName]?.array
				else {
					return nil
			}
			self.init(name: name, children: childlist.compactMap{Child(avroValue: $0)})
		}
	}


    
	func testCanRetrieveInformationFromSchemaDescriptor() {
		XCTAssertNotNil(Child.schemaDescriptor.jsonRepresentation)
		XCTAssertNotNil(Child.schemaDescriptor.schema)
	}
	
	func testChildConstructableFromAvroValue() {
		// GIVEN
		let original = Child(name: "First Child", age: 12)
		
		// WHEN
		let avroValue = original.toAvro()
		
		// THEN
		XCTAssertNotNil(avroValue)
		
		// WHEN
		let reconstructed = Child(avroValue: avroValue)
		
		// THEN
		XCTAssertNotNil(reconstructed)
		XCTAssertEqual(reconstructed, original)
	}
	
	func testChildConstructableFromBinaryRepresentation() {
		// GIVEN
		let original = Child(name: "First Child", age: 12)
		
		// WHEN
		let binaryValue = original.toAvro().encode(Child.schemaDescriptor.schema)
		
		// THEN
		XCTAssertNotNil(binaryValue)
		
		if let binaryValue = binaryValue {
			// WHEN
			let avroValue = AvroValue(schema: Child.schemaDescriptor.schema, withBytes: binaryValue)
			let reconstructed = Child(avroValue: avroValue)
			
			// THEN
			XCTAssertNotNil(reconstructed)
			XCTAssertEqual(reconstructed, original)
			
			print("### Child binary size: \(binaryValue.count) bytes ###")
		}
	}
	
	func testParentConstructableFromAvroValue() {
		// GIVEN
		let original = Parent(name: "Parents's name", children: [Child(name: "First Child", age: 12), Child(name: "Second child", age: 9)])
		
		// WHEN
		let avroValue = original.toAvro()
		
		// THEN
		XCTAssertNotNil(avroValue)
		
		// WHEN
		let reconstructed = Parent(avroValue: avroValue)
		
		// THEN
		XCTAssertNotNil(reconstructed)
		XCTAssertEqual(reconstructed, original)
	}
	
	func testParentConstructableFromBinaryRepresentation() {
		// GIVEN
		let original = Parent(name: "Parents's name", children: [Child(name: "First Child", age: 12), Child(name: "Second child", age: 9)])
		
		// WHEN
		let binaryValue = original.toAvro().encode(Parent.schemaDescriptor.schema)
		
		// THEN
		XCTAssertNotNil(binaryValue)
		
		if let binaryValue = binaryValue {
			// WHEN
			let avroValue = AvroValue(schema: Parent.schemaDescriptor.schema, withBytes: binaryValue)
			let reconstructed = Parent(avroValue: avroValue)
			
			// THEN
			XCTAssertNotNil(reconstructed)
			XCTAssertEqual(reconstructed, original)
			
			print("### Parent binary size: \(binaryValue.count) bytes ###")
		}
	}
}
