//
//  ResultReadModel.swift
//  FutaBluetooth
//
//  Created by mac on 22/09/2022.
//

enum ReadEnum: String {
    case START
    case NODATA
    
    init?(message: String) throws {
        let stringArray = message.components(separatedBy: ["|"]) //$$$TAXI1|START|211###
        if stringArray.count < 3 {
            throw BleError.resultIncorrectFormat
        }
        let result = stringArray[1]
        self.init(rawValue: result)
    }
}

public struct ResultReadModel {
    let km: Int
    let tgchophut: Int
    let tgchogiay: Int
    let tien: Int
    let idcouc: Int
    let tglenxe: String
    let tgxuongxe: String
    
    init(message: String) throws {
        let stringArray = message.components(separatedBy: ["|", ";"])
        if stringArray.count < 8 {
            throw BleError.resultIncorrectFormat
        }
        km = stringArray[1].toInt()
        tgchophut = stringArray[2].toInt()
        tgchogiay = stringArray[3].toInt()
        tien = stringArray[4].toInt()
        idcouc = stringArray[5].toInt()
        tglenxe = stringArray[6]
        tgxuongxe = stringArray[7]
        
    }
}
