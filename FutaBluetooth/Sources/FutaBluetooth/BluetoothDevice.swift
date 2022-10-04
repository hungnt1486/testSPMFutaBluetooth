//
//  BluetoothSerial.swift (originally DZBluetoothSerialHandler.swift)
//  HM10 Serial
//
//  Created by Alex on 09-08-15.
//  Copyright (c) 2015 Balancing Rock. All rights reserved.
//
//  IMPORTANT: Don't forget to set the variable 'writeType' or else the whole thing might not work.
//

import UIKit
import CoreBluetooth

/// Global serial handler, don't forget to initialize it with init(delgate:)
var serial: BluetoothDevice!

protocol BluetoothDeviceDelegate {
    func bluetoothDeviceIsReady(bluetoothDevice: BluetoothDevice)
    func bluetoothDidReceiveMessage(message: String)
    func bluetoothDidReceiveSyncResult(result: ResultCommandSyncModel)
    func bluetoothDidReceiveACK(command:BLECommand, ack: ResultACKModel)
    func bluetoothDidReceiveChotca(chotca: ResultChotcaModel)
    func bluetoothDidReceiveViewChotca(viewChotca: ResultChotcaModel?, isReady: Bool)
    func bluetoothDidReceiveRead1(result: [ResultReadModel]?, isReady: Bool)
    func bluetoothDidReceiveRead2(result: [ResultReadModel]?, isReady: Bool)
    func bluetoothDidReceiveError(error: BleError)
}


public class BluetoothDevice: NSObject, CBPeripheralDelegate {
    
    var delegate: BluetoothDeviceDelegate?
    
    let peripheral: CBPeripheral
    var lastUpdate : Date
    var rssi = NSNumber()
    
    public weak var writeCharacteristic: CBCharacteristic?
    private var writeType = CBCharacteristicWriteType.withResponse
    private var currentCommand: BLECommand?
    
    var maxChunkSize = 20
    
    /// Buffer of data to be sent
    private var buffer = Data()
    
    /// Time interval between chunks of max size (seconds)
    private let chunkInterval = 0.1
    
    /// Time next chunk may be sent
    private var nextChunkTime = Date()
    
    
    private var receiveDataString = ""
    
    public var name = ""
    
    public init(peripheral:  CBPeripheral) {
        self.peripheral = peripheral
        self.lastUpdate = Date()
        self.name = peripheral.name ?? ""
        super.init()
    }
    
    func discoverServices(services: [CBUUID]) {
        peripheral.delegate = self
        peripheral.discoverServices(services)
    }
    
    func sendCommand(command: BLECommand) {
        if currentCommand == nil {
            currentCommand = command
            sendDataToDevice(command.toData())
        }
    }
    
    
    //MARK: private
    private func sendDataToDevice(_ data: Data) {
        addToBuffer(data)
    }
    
    private func addToBuffer(_ data: Data) {
        buffer.append(data)
        if nextChunkTime < Date() {
            sendNextChunk()
        }
    }
    
    private func sendNextChunk() {
        let willBeLast = buffer.count <= maxChunkSize
        let start = buffer.startIndex
        let end = buffer.endIndex
        let chunkEnd = willBeLast ? end : start.advanced(by: maxChunkSize)
        let chunk = buffer.subdata(in: start..<chunkEnd)
        let newBuffer = willBeLast ? Data() : buffer.subdata(in: chunkEnd..<end)
        
        buffer = newBuffer
        peripheral.writeValue(chunk, for: writeCharacteristic!, type: writeType)
        
        if !buffer.isEmpty {
            nextChunkTime = Date.init(timeIntervalSinceNow: chunkInterval)
            delay(seconds: chunkInterval, callback: sendNextChunk)
        }
        if willBeLast {
            _ = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { [weak self] _ in
                self?.currentCommand = nil
            })
        }
    }
    
    private func handleReceiveMessage(message: String) {
        debugPrint("handleReceiveMessage: \(message)")
        DispatchQueue.main.async {
            do {
                guard let currentCommand = self.currentCommand else { return }
                switch (currentCommand) {
                case .sync:
                    
                    let resultCommandSyncModel = try ResultCommandSyncModel(message: message)
                    self.delegate?.bluetoothDidReceiveSyncResult(result: resultCommandSyncModel)
                    self.currentCommand = nil
                    
                case .hired, .print, .vacant, .stop:
                    
                    let resultACK = try ResultACKModel(message: message)
                    self.delegate?.bluetoothDidReceiveACK(command: currentCommand, ack: resultACK ?? .ERR)
                    self.currentCommand = nil
                    
                    
//                case .chotca:
//                    let resultChotcaModel = try ResultChotcaModel(message: message)
//                    self.delegate?.bluetoothDidReceiveChotca(chotca: resultChotcaModel)
//                    self.currentCommand = nil
                case .view, .chotca:
                    
                    if try ResultACKModel(message: message) != nil {
                        self.delegate?.bluetoothDidReceiveViewChotca(viewChotca: nil, isReady: false)
                    } else {
                        let resultViewChotcaModel = try ResultChotcaModel(message: message)
                        self.delegate?.bluetoothDidReceiveViewChotca(viewChotca: resultViewChotcaModel, isReady: true)
                    }
                    self.currentCommand = nil
                    
                    
                case .read1, .read2:
                    
                    if try ResultACKModel(message: message) != nil {
                        if case .read1 = currentCommand {
                            self.delegate?.bluetoothDidReceiveRead1(result: nil, isReady: false)
                            
                        } else {
                            self.delegate?.bluetoothDidReceiveRead2(result: nil, isReady: false)
                        }
                        self.currentCommand = nil
                        return
                    }
                    
                    let readEnum = try ReadEnum(message: message)
                    if readEnum == .START {
                        self.arrayResult = [AnyObject]()
                    } else if readEnum == .NODATA {
                        if let readArray = self.arrayResult as? [ResultReadModel] {
                            
                            if case .read1 = currentCommand {
                                self.delegate?.bluetoothDidReceiveRead1(result: readArray, isReady: true)
                            } else {
                                self.delegate?.bluetoothDidReceiveRead2(result: readArray, isReady: true)
                            }
                            self.arrayResult.removeAll()
                        }
                        self.currentCommand = nil
                        
                    } else {
                        let resultReadModel = try ResultReadModel(message: message)
                        self.arrayResult.append(resultReadModel)
                    }
                    
                }
                
            } catch {
                debugPrint("== handle message error: \(error)")
                if let bleError = error as? BleError {
                    self.delegate?.bluetoothDidReceiveError(error: bleError)
                }
            }
        }
        
        
    }
    
    var arrayResult = [Any]()
    
    // MARK: - CBPeripheral Delegate
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // discover the 0xFFE1 characteristic for all services (though there should only be one)
        for service in peripheral.services! {
            peripheral.discoverCharacteristics([Constant.readCharacteristicUUID, Constant.writeCharacteristicUUID], for: service)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        var foundRead = false
        var foundWrite = false
        
        // check whether the characteristics we're looking for are present - just to be sure
        for characteristic in service.characteristics! {
            if characteristic.uuid == Constant.readCharacteristicUUID {
                foundRead = true
                
                // subscribe to this value (so we'll get notified when there is serial data for us..)
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
            if characteristic.uuid == Constant.writeCharacteristicUUID {
                foundWrite = true
                
                // find out how to write to this characteristic
                writeType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
                
                // keep a reference to this characteristic so we can write to it
                writeCharacteristic = characteristic
            }
        }
        
        if foundRead && foundWrite {
            // notify the delegate we're ready for communication
            delegate?.bluetoothDeviceIsReady(bluetoothDevice: self)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        receiveDataString = ""
        guard error == nil else {
            debugPrint("== Error discovering services: error")
            
            return
        }
        debugPrint("== Function: \(#function),Line: \(#line)")
        debugPrint("== Message sent")
        
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // notify the delegate in different ways
        // if you don't use one of these, just comment it (for optimum efficiency :])
        
        let data = characteristic.value
        
      //  debugPrint("== didUpdateValueFor: \(data)")
        
        guard data != nil && !data!.isEmpty else { return }
        
        // first the data
        //delegate.serialDidReceiveData(data!)
        
        // then the string
        DispatchQueue.main.async {
            //if let str = String(data: data!, encoding: .utf8) {
            let str = String(decoding: data!, as: UTF8.self)
            //  delegate.serialDidReceiveString(str)
            self.receiveDataString += str
            //debugPrint("== Received an  string: \(str)")
            if self.receiveDataString.contains(Constant.checkSumSeperator) {
                self.delegate?.bluetoothDidReceiveMessage(message: self.receiveDataString)
                self.handleReceiveMessage(message: self.receiveDataString)
                self.receiveDataString = ""
            }
            
            //            } else {
            //                debugPrint("== Received an invalid string!")
            //            }
        }
        
        // now the bytes array
        //var bytes = [UInt8](repeating: 0, count: data!.count / MemoryLayout<UInt8>.size)
        //(data! as NSData).getBytes(&bytes, length: data!.count)
        //delegate.serialDidReceiveBytes(bytes)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        rssi = RSSI
    }
    
}
