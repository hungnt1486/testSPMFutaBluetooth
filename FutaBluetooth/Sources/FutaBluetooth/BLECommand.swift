//
//  BLECommand.swift
//  FutaBluetooth
//
//  Created by mac on 20/09/2022.
//

import Foundation

public enum BleError: Swift.Error {
    case resultIncorrectFormat
}

extension BleError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .resultIncorrectFormat: return "Dữ liệu sai đinh dạng"
        }
    }
}

public enum BLECommand {
    
    case sync
    case print(companyName: String, address: String, companyPhone: String, plateNumber: String, driverNumber: String, taxCode: String, vat: Int, id: String?)
    case hired
    case vacant
    case stop
    case chotca
    case view
    case read1
    case read2(fromIndex: Int)
    
    func toData() -> Data {
        switch(self) {
        case .print(let companyName, let address, let companyPhone, let plateNumber, let driverNumber, let taxCode, let vat, let id):
            let bodyCommand =  "TAXI1" + Constant.seperator
                                + self.description() + Constant.seperator
                                + companyName + Constant.seperator
                                + address + Constant.seperator
                                + companyPhone + Constant.seperator
                                + plateNumber + Constant.seperator
                                + driverNumber + Constant.seperator
                                + taxCode + Constant.seperator
                                + "\(vat)" + Constant.seperator
                                + (id != nil ? "\(id!)\(Constant.seperator)" : "")
            
            let checksum = checkSum(message: bodyCommand)
            let command = Constant.prefixCommand + "," + bodyCommand + "\(checksum)#\r\n"
            debugPrint("== command: \(command)")
            return Data(command.utf8)
            
        case .read2(let fromIndex):
            let bodyCommand = "TAXI1" + Constant.seperator
            + self.description() + Constant.seperator
            + "\(fromIndex)" + Constant.seperator
            let checksum = checkSum(message: bodyCommand)
            let command = Constant.prefixCommand + "," + bodyCommand + "\(checksum)#\r\n"
            debugPrint("== command: \(command)")
            return Data(command.utf8)
            
        case .hired, .vacant, .stop, .sync, .chotca, .view, .read1:
            let bodyCommand = "TAXI1" + Constant.seperator + self.description() + Constant.seperator
            let checksum = checkSum(message: bodyCommand)
            let command = Constant.prefixCommand + "," + bodyCommand + "\(checksum)#\r\n"
            debugPrint("== command: \(command)")
            return Data(command.utf8)
        }
    }
    
    //MARK: private
    
    private func description() -> String {
        switch self {
        case .sync:
            return "SYNC"
        case .hired:
            return "HIRED"
        case .vacant:
            return "VACANT"
        case .stop:
            return "STOP"
        case .print:
            return "PRINT"
        case .chotca:
            return "DELETE"
        case .view:
            return "VIEW"
        case .read1:
            return "READ1"
        case .read2:
            return "READ2"
        }
    }
    
    private func checkSum(message: String) -> Int {
        let count = message.countDecimal() & 0xff
        return count
    }
}
