//
//  Flattenable.swift
//  BlueSteel
//
//  Created by Michael Radtke on 18.05.18.
//  Copyright © 2018 Gilt Groupe. All rights reserved.
//

import Foundation


public protocol Flattenable {
	
	init?(_ container: Flattened)
	init?(flattenedData: Data?)
	
	var flattened : Flattened {get}
}


public extension Flattenable {
	
	init?(_ container: Flattened?) {
		guard let container = container else { return nil }
		self.init(container)
	}
	
	init?(flattenedData: Data?) {
		guard
			let data = flattenedData,
			let container = Flattened(data)
			else { return nil }
		self.init(container)
	}
}
