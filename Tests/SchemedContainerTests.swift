//
//  SchemedContainerTests.swift
//  BlueSteelTests
//
//  Created by Michael Radtke on 17.01.18.
//  Copyright © 2018 Gilt Groupe. All rights reserved.
//

import XCTest
import BlueSteel


class SchemedContainerTests: XCTestCase {
	
	let testSchema = Schema("{\"name\":\"simpleString\",\"type\":\"string\"}")
	let testData = "Hello"

	
	func testReceivedSchemedContainerMust3BytesLongAtLeast() {
		// GIVEN
		var input: [UInt8] = [0x01, 0x02]
		
		// WHEN
		var rsc = SchemedContainer(input)
		
		// THEN
		XCTAssertNil(rsc)
		
		// GIVEN
		input.append(0x03)
		
		// WHEN
		rsc = SchemedContainer(input)
		
		// THEN
		XCTAssertNotNil(rsc)
	}
    
	func testReceivingSchemaContainerWithoutData() {
		// GIVEN
		let input: [UInt8] = [0x24, 0x21, 0x72]
		
		// WHEN
		let receivingSchemdContainer = SchemedContainer(input)!
		
		// THEN
		XCTAssertEqual(receivingSchemdContainer.schemaId, 9249)
		XCTAssertEqual(receivingSchemdContainer.schemaVersion, 114)
		XCTAssertEqual(receivingSchemdContainer.content.isEmpty, true)
	}
	
	func testReceivingSchemaContainerWithData() {
		// GIVEN
		let input: [UInt8] = [0x24, 0x22, 0x73, 0x23, 0x00, 0xff, 0xce]
		
		// WHEN
		let receivingSchemdContainer = SchemedContainer(input)!
		
		// THEN
		XCTAssertEqual(receivingSchemdContainer.schemaId, 9250)
		XCTAssertEqual(receivingSchemdContainer.schemaVersion, 115)
		XCTAssertEqual(receivingSchemdContainer.content.isEmpty, false)
		XCTAssertEqual(receivingSchemdContainer.content, [0x23, 0x00, 0xff, 0xce])
	}
	
	func testSendingSchemedContainerWithoutData() {
		// GIVEN, WHEN
		let sendingSchemedContainer = SchemedContainerFactory(schemaId: 9249, schemaVersion: 114)
		
		// THEN
		XCTAssertEqual(sendingSchemedContainer.create.binaryBuffer,[0x24, 0x21, 0x72])
	}
	
	func testSendingSchemedContainerWithData() {
		// GIVEN
		let ssc = SchemedContainerFactory(schemaId: 9250, schemaVersion: 115, schema: testSchema)
		
		// WHEN
		let s = ssc.createFor(testData.toAvro())
		
		// THEN
		XCTAssertEqual(s.data, Data([0x24, 0x22, 0x73, 0x0a, 0x48, 0x65, 0x6c, 0x6c, 0x6f]))
	}
	
	func testExtractAvroFromSchemedContainer() {
		// GIVEN
		let ssc = SchemedContainerFactory(schemaId: 9250, schemaVersion: 115, schema: testSchema)
		let sc = ssc.createFor(testData.toAvro())
		
		do {
			// WHEN
			let extracted = try ssc.extract(sc)?.string
		
			// THEN
			XCTAssertNotNil(extracted)
			XCTAssertEqual(extracted!, testData)
		} catch {
			XCTFail();
		}
	}
	
	func testExtractAvroFromSimpleSchemedContainer() {
		// GIVEN
		let ssc = SchemedContainerFactory(schemaId: 9249, schemaVersion: 114)
		let sc = ssc.create
		
		do {
			// WHEN
			let extracted = try ssc.extract(sc)
			
			// THEN
			XCTAssertNil(extracted)
		} catch {
			XCTFail();
		}
	}
	
	func testExtractFailsWhenSchemaIdDoesNotMatch() {
		// GIVEN
		let ssc1 = SchemedContainerFactory(schemaId: 9000, schemaVersion: 0)
		let ssc2 = SchemedContainerFactory(schemaId: 9001, schemaVersion: 0)
		let sc = ssc2.create
		
		XCTAssertThrowsError(try ssc1.extract(sc))
	}
	
	func testExtractFailsWhenSchemaVersionDoesNotMatch() {
		// GIVEN
		let ssc1 = SchemedContainerFactory(schemaId: 9000, schemaVersion: 0)
		let ssc2 = SchemedContainerFactory(schemaId: 9000, schemaVersion: 1)
		let sc = ssc2.create
		
		XCTAssertThrowsError(try ssc1.extract(sc))
	}
}
