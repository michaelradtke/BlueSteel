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
		let input: [UInt8] = [0x24, 0x22, 0x73]
		
		// WHEN
		let receivingSchemdContainer = SchemedContainer(input)!
		
		// THEN
		XCTAssertEqual(receivingSchemdContainer.schemaId, 9250)
		XCTAssertEqual(receivingSchemdContainer.schemaVersion, 115)
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
		let sendingSchemedContainer = SchemedContainerFactory(schemaId: 9250, schemaVersion: 115)
		
		// THEN
		XCTAssertEqual(sendingSchemedContainer.create.binaryBuffer,[0x24, 0x22, 0x73])
	}
	
	func testSendingSchemedContainerWithData() {
		// GIVEN
		let schema = Schema("{\"name\":\"simpleString\",\"type\":\"string\"}")!
		let data = "Hello"
		let ssc = SchemedContainerFactory(schemaId: 9250, schemaVersion: 115, schema: schema)
		
		// WHEN
		let s = ssc.createFor(data.toAvro())
		
		// THEN
		XCTAssertEqual(s.data, Data([0x24, 0x22, 0x73, 0x0a, 0x48, 0x65, 0x6c, 0x6c, 0x6f]))
	}
}
