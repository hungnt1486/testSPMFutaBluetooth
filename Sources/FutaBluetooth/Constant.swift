//
//  Constant.swift
//  FutaBluetooth
//
//  Created by mac on 20/09/2022.
//

import Foundation
import CoreBluetooth

struct Constant {
    static var prefixCommand = "*$$$FTB"
    static var seperator = "|"
    static var checkSumSeperator = "###"
    
    
    static let serviceUUID = [CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")]
    
    /// UUID of the read characteristic to look for.
    static let readCharacteristicUUID = CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")
    
    /// UUID of the write characteristic to look for.
    static let writeCharacteristicUUID = CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
}
