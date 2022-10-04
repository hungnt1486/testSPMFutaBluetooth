//
//  ResultCommandSyncModel.swift
//  FutaBluetooth
//
//  Created by mac on 21/09/2022.
//

import Foundation

public struct ResultCommandSyncModel {
    let serial: String //serial of device
    let id: String // id of device
    let g: Int
    let longitude: Double
    let latitude: Double
    let vantocgps: Int //km/h
    let vantocco: Int //km/h
    let tx: Int
    let tongtien: Int
    let tongkm: Int // meter
    let tongkmsd: Int
    let tongcuoc: Int // tổng cuốc đồng hồ đã chạy
    let chichxung: Int
    let offpow: Int // số lần mất nguồn
    let cuoc0km: Int
    let tghientai: String
    let km: Int // quãng đường cuốc xe đang chạy, đơn vị m
    let tgcho: Int // thời gian chờ, đơn vị giây
    let tien: Int // số tiền cuốc xe đang chạy, đơn vị 100vnd
    let tglenxe: String // mmhhDDMM: phút,giờ,ngày,tháng (thời gian khách lên xe của cuốc đang chạy).
    let ten: String
    let gplx: String
    let trangthai: Int
    
   public init(message: String) throws {
       
       let stringArray = message.components(separatedBy: ["&"])
       let tabString = stringArray[1]
       let gString = stringArray[2]
       let txString = stringArray[3]
       
        debugPrint("== result: \(stringArray)")
       
       let tabValueArray = tabString.components(separatedBy: [";", "=", ":"])
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
       
       let txValueArray = txString.components(separatedBy: [":", ";", "="])
       tx = txValueArray[1].toInt()
       if tx == 1 {
           if txValueArray.count < 11 {
               throw BleError.resultIncorrectFormat
           }
           
           tongtien = txValueArray[2].toInt()
           tongkm = txValueArray[3].toInt()
           tongkmsd = txValueArray[4].toInt()
           tongcuoc = txValueArray[5].toInt()
           chichxung = txValueArray[6].toInt()
           offpow = txValueArray[7].toInt()
           cuoc0km = txValueArray[8].toInt()
           tghientai = txValueArray[9]
           
           km = 0
           tgcho = 0
           tien = 0
           tglenxe = ""
           
       } else {
           if txValueArray.count < 9 {
               throw BleError.resultIncorrectFormat
           }
           
           km = txValueArray[2].toInt()
           tgcho = txValueArray[3].toInt()
           tien = txValueArray[4].toInt()
           tongcuoc = txValueArray[5].toInt()
           tglenxe = txValueArray[6]
           tghientai = txValueArray[7]
           
           tongtien = 0
           tongkm = 0
           tongkmsd = 0
           chichxung = 0
           offpow = 0
           cuoc0km = 0
           
           
       }
       
   
       let lxString = stringArray[4]
       let lxValueArray = lxString.components(separatedBy: [":", ";", "="])
       if lxValueArray.count < 5 {
           throw BleError.resultIncorrectFormat
       }
       ten =  lxValueArray[1]
       gplx = lxValueArray[2]
       trangthai = lxValueArray[4].toInt()
       
       
   }
}
