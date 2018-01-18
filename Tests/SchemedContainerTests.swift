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
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
	
	func testReceivedSchemedContainerMust3BytesLongAtLeast() {
		// GIVEN
		var input: [UInt8] = [0x01, 0x02]
		
		// WHEN
		var rsc = ReceivingSchemedContainer(binaryBuffer: input)
		
		// THEN
		XCTAssertNil(rsc)
		
		// GIVEN
		input.append(0x03)
		
		// WHEN
		rsc = ReceivingSchemedContainer(binaryBuffer: input)
		
		// THEN
		XCTAssertNotNil(rsc)
	}
    
	func testReceivingSchemaContainerWithoutData() {
		// GIVEN
		let input: [UInt8] = [0x24, 0x22, 0x73]
		
		// WHEN
		let receivingSchemdContainer = ReceivingSchemedContainer(binaryBuffer: input)!
		
		// THEN
		XCTAssertEqual(receivingSchemdContainer.schemaId, 9250)
		XCTAssertEqual(receivingSchemdContainer.schemaVersion, 115)
		XCTAssertEqual(receivingSchemdContainer.serializedContent.isEmpty, true)
	}
	
	func testReceivingSchemaContainerWithData() {
		// GIVEN
		let input: [UInt8] = [0x24, 0x22, 0x73, 0x23, 0x00, 0xff, 0xce]
		
		// WHEN
		let receivingSchemdContainer = ReceivingSchemedContainer(binaryBuffer: input)!
		
		// THEN
		XCTAssertEqual(receivingSchemdContainer.schemaId, 9250)
		XCTAssertEqual(receivingSchemdContainer.schemaVersion, 115)
		XCTAssertEqual(receivingSchemdContainer.serializedContent.isEmpty, false)
		XCTAssertEqual(receivingSchemdContainer.serializedContent, [0x23, 0x00, 0xff, 0xce])
	}
	
	func testSendingSchemedContainerWithoutData() {
		// GIVEN, WHEN
		let sendingSchemedContainer = SendingSchemedContainer(schemaId: 9250, schemaVersion: 115)
		
		// THEN
		XCTAssertEqual(sendingSchemedContainer.serialized, Data([0x24, 0x22, 0x73]))
	}
	
	func testSendingSchemedContainerWithData() {
		// GIVEN
		let schema = Schema("{\"name\":\"simpleString\",\"type\":\"string\"}")!
		let data = "Hello"
		let ssc = SendingSchemedContainer(schemaId: 9250, schemaVersion: 115, schema: schema)
		
		// WHEN
		let s = ssc.serializedFor(data.toAvro())
		
		// THEN
		XCTAssertEqual(s, Data([0x24, 0x22, 0x73, 0x0a, 0x48, 0x65, 0x6c, 0x6c, 0x6f]))
	}
}
