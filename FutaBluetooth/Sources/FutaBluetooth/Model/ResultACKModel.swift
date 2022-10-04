//
//  ResultACKModel.swift
//  FutaBluetooth
//
//  Created by mac on 21/09/2022.
//

public enum ResultACKModel: String {
    case OK
    case ERR
    
    init?(message: String) throws {
        let stringArray = message.components(separatedBy: ["|"]) //$$$TAXI1|ERR|072###
        if stringArray.count < 3 {
            throw BleError.resultIncorrectFormat
        }
        let result = stringArray[1]
        self.init(rawValue: result)
    }
}
