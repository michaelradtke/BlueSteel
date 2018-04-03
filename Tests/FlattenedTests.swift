//
//  FlattenedTests.swift
//  BlueSteelTests
//
//  Created by Michael Radtke on 17.01.18.
//  Copyright © 2018 Gilt Groupe. All rights reserved.
//

import XCTest
import BlueSteel


class FlattenedTests: XCTestCase {
	
	let testSchema = Schema("{\"name\":\"simpleString\",\"type\":\"string\"}")!
	let testData = "Hello"

	
	func testReceivedFlattenedMust3BytesLongAtLeast() {
		// GIVEN
		var input: [UInt8] = [0x01, 0x02]
		
		// WHEN
		var rsc = Flattened(input)
		
		// THEN
		XCTAssertNil(rsc)
		
		// GIVEN
		input.append(0x03)
		
		// WHEN
		rsc = Flattened(input)
		
		// THEN
		XCTAssertNotNil(rsc)
	}
    
	func testReceivingFlattenedWithoutData() {
		// GIVEN
		let input: [UInt8] = [0x24, 0x21, 0x72]
		
		// WHEN
		let receivingSchemdContainer = Flattened(input)!
		
		// THEN
		XCTAssertEqual(receivingSchemdContainer.schemaId, 9249)
		XCTAssertEqual(receivingSchemdContainer.schemaVersion, 114)
		XCTAssertEqual(receivingSchemdContainer.content.isEmpty, true)
	}
	
	func testReceivingFlattenedWithData() {
		// GIVEN
		let input: [UInt8] = [0x24, 0x22, 0x73, 0x23, 0x00, 0xff, 0xce]
		
		// WHEN
		let receivingSchemdContainer = Flattened(input)!
		
		// THEN
		XCTAssertEqual(receivingSchemdContainer.schemaId, 9250)
		XCTAssertEqual(receivingSchemdContainer.schemaVersion, 115)
		XCTAssertEqual(receivingSchemdContainer.content.isEmpty, false)
		XCTAssertEqual(receivingSchemdContainer.content, [0x23, 0x00, 0xff, 0xce])
	}
	
	func testSendingFlattenedWithoutData() {
		// GIVEN, WHEN
		let sendingSchemedContainer = PrimitiveFlatteningFactory(schemaId: 9249, schemaVersion: 114)
		
		// THEN
		XCTAssertEqual(sendingSchemedContainer.created.binaryBuffer,[0x24, 0x21, 0x72])
	}
	
	func testSendingFlattenedWithData() {
		// GIVEN
		let ssc = FlatteningFactory(schemaId: 9250, schemaVersion: 115, schema: testSchema)
		
		// WHEN
		let s = ssc.create(testData.toAvro())
		
		// THEN
		XCTAssertEqual(s.data, Data([0x24, 0x22, 0x73, 0x0a, 0x48, 0x65, 0x6c, 0x6c, 0x6f]))
	}
	
	func testExtractAvroFromSchemedContainer() {
		// GIVEN
		let ssc = FlatteningFactory(schemaId: 9250, schemaVersion: 115, schema: testSchema)
		let sc = ssc.create(testData.toAvro())
		
		do {
			// WHEN
			let extracted = try ssc.extract(sc).string
		
			// THEN
			XCTAssertNotNil(extracted)
			XCTAssertEqual(extracted!, testData)
		} catch {
			XCTFail();
		}
	}
	
	func testExtractAvroFromSimpleSchemedContainer() {
		// GIVEN
		let ssc = PrimitiveFlatteningFactory(schemaId: 9249, schemaVersion: 114)
		let sc = ssc.created
		
		do {
			// WHEN
			try ssc.extract(sc)
			
			// THEN
			
		} catch {
			XCTFail();
		}
	}
	
	func testExtractFailsWhenSchemaIdDoesNotMatch() {
		// GIVEN
		let ssc1 = PrimitiveFlatteningFactory(schemaId: 9000, schemaVersion: 0)
		let ssc2 = PrimitiveFlatteningFactory(schemaId: 9001, schemaVersion: 0)
		let sc = ssc2.created
		
		XCTAssertThrowsError(try ssc1.extract(sc))
	}
	
	func testExtractFailsWhenSchemaVersionDoesNotMatch() {
		// GIVEN
		let ssc1 = PrimitiveFlatteningFactory(schemaId: 9000, schemaVersion: 0)
		let ssc2 = PrimitiveFlatteningFactory(schemaId: 9000, schemaVersion: 1)
		let sc = ssc2.created
		
		XCTAssertThrowsError(try ssc1.extract(sc))
	}
}
