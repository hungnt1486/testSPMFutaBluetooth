//
//  ResultChotcaModel.swift
//  FutaBluetooth
//
//  Created by mac on 21/09/2022.
//

public struct ResultChotcaModel {
    let serial: String //serial of device
    let id: String // id of device
    let g: Int
    let longitude: Double
    let latitude: Double
    let vantocgps: Int //km/h
    let vantocco: Int //km/h
    
    let tongtien_dauca: Int
    let tongkm_dauca: Int
    let tongkmsd_dauca: Int
    let tongcuoc_dauca: Int
    let chichxung_dauca: Int
    let offpow_dauca: Int
    let cuoc0km_dauca: Int
    let tg_dauca: String
    
    let tongtien_chotca: Int
    let tongkm_chotca: Int
    let tongkmsd_chotca: Int
    let tongcuoc_chotca: Int
    let chichxung_chotca: Int
    let offpow_chotca: Int
    let cuoc0km_chotca: Int
    let tghientai: String
    
    
    public init(message: String) throws {
        
        let stringArray = message.components(separatedBy: ["&"])
        let tabString = stringArray[1]
        let gString = stringArray[2]
        let c1String = stringArray[3]
        let c2String = stringArray[4]
        
        let tabValueArray = tabString.components(separatedBy: [":", ";"])
        if tabValueArray.count < 3 {
            throw BleError.resultIncorrectFormat
        }
        serial = tabValueArray[1]
        id = tabValueArray[2]
        
        let gValueArray = gString.components(separatedBy: [":", ";", "="])
        if gValueArray.count < 6 {
            throw BleError.resultIncorrectFormat
        }
        g = gValueArray[1].toInt()
        longitude = gValueArray[2].toDouble()
        latitude = gValueArray[3].toDouble()
        vantocgps = gValueArray[4].toInt()
        vantocco = gValueArray[5].toInt()
        
        let c1ValueArray = c1String.components(separatedBy: [":", ";", "="])
        if c1ValueArray.count < 10 {
            throw BleError.resultIncorrectFormat
        }
        tongtien_dauca = c1ValueArray[2].toInt()
        tongkm_dauca = c1ValueArray[3].toInt()
        tongkmsd_dauca = c1ValueArray[4].toInt()
        tongcuoc_dauca = c1ValueArray[5].toInt()
        chichxung_dauca = c1ValueArray[6].toInt()
        offpow_dauca  = c1ValueArray[7].toInt()
        cuoc0km_dauca = c1ValueArray[8].toInt()
        tg_dauca = c1ValueArray[9]
        
        let c2ValueArray = c2String.components(separatedBy: [":", ";", "=", "|"])
        if c2ValueArray.count < 10 {
            throw BleError.resultIncorrectFormat
        }
        tongtien_chotca = c2ValueArray[2].toInt()
        tongkm_chotca = c2ValueArray[3].toInt()
        tongkmsd_chotca = c2ValueArray[4].toInt()
        tongcuoc_chotca = c2ValueArray[5].toInt()
        chichxung_chotca = c2ValueArray[6].toInt()
        offpow_chotca = c2ValueArray[7].toInt()
        cuoc0km_chotca = c2ValueArray[8].toInt()
        tghientai = c2ValueArray[9]
        
        //   debugPrint("==  c2ValueArray: \(c2ValueArray)")
    }
}
