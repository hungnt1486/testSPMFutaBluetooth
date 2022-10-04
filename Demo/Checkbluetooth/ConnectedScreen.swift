//
//  ConnectedScreen.swift
//  Checkbluetooth
//
//  Created by mac on 20/09/2022.
//

import Foundation
import UIKit
import FutaBluetooth

class ConnectedScreen: UIViewController {
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var messageReceiveLabel: UILabel!
    
    var bluetoothController: FutaBluetoothController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        statusLabel.text = "Status: Connected"
        bluetoothController = FutaBluetoothController.shared
        bluetoothController?.delegate = self
        bluetoothController?.setAutoReconnect(auto: true)
        if let name = bluetoothController?.connectedPeripheral?.name {
            nameLabel.text = "Device name: \(name)"
        } else {
            nameLabel.text = "Device name:"
        }
        
    }
    
    @IBAction func buttonSyncTouch() {
        bluetoothController?.sendCommandToBluetoothDevice(command: BLECommand.sync)
    }
    
    @IBAction func buttonPrintTouch() {
        bluetoothController?.sendCommandToBluetoothDevice(command: BLECommand.print(companyName: "CTy Co Phan VT Taxi ABC",
                                                                                    address: "So 98, To 17, Khu Cau Xeo, Thi Tran Tay Tien, Huyen Long Lanh, Tinh Long Lanh, Viet Nam",
                                                                                    companyPhone: "0090909999",
                                                                                    plateNumber: "ABC56789",
                                                                                    driverNumber: "3839",
                                                                                    taxCode:"33445577",
                                                                                    vat: 10,
                                                                                    id: nil))
    }
    
    @IBAction func buttonHiredTouch() {
        bluetoothController?.sendCommandToBluetoothDevice(command: BLECommand.hired)
    }
    
    @IBAction func buttonChotcaTouch() {
        bluetoothController?.sendCommandToBluetoothDevice(command: .chotca)
    }
    
    @IBAction func buttonRead1Touch() {
        bluetoothController?.sendCommandToBluetoothDevice(command: .read1)
    }
    
    @IBAction func buttonVacantTouch() {
        bluetoothController?.sendCommandToBluetoothDevice(command: .vacant)
    }
    
    @IBAction func buttonViewTouch() {
        bluetoothController?.sendCommandToBluetoothDevice(command: .view)
    }
    
    @IBAction func autoReconnect(sender: UISwitch) {
        bluetoothController?.setAutoReconnect(auto: sender.isOn)
    }
}

extension ConnectedScreen: FutaBluetoothDelegate {
    func bluetoothDidReceiveError(error: BleError) {
        print("== error: \(error.localizedDescription)")
    }
    
    func bluetoothDidReceiveRead2(result: [ResultReadModel]?, isReady: Bool) {
        
    }
    
    func bluetoothDidReceiveRead1(result: [ResultReadModel]?, isReady: Bool) {
        print("result: \(result), isReady: \(isReady)")
    }
    
    func bluetoothDidReceiveACK(command: BLECommand, ack: ResultACKModel) {
        print("command: \(command)")
        print("result ack: \(ack)")
    }
    
    func bluetoothDidReceiveViewChotca(viewChotca: ResultChotcaModel?, isReady: Bool) {
        print("result: \(viewChotca), isReady: \(isReady)")
    }
    
    func bluetoothDidReceiveChotca(chotca: ResultChotcaModel) {
        print("result: \(chotca)")
    }
    
    func bluetoothDidReceiveSyncResult(result: ResultCommandSyncModel) {
        print("result: \(result)")
    }
    
    
    
    func serialDidChangeState() {
        
    }
    
    func serialDidDisconnect(_ bluetoothDevice: BluetoothDevice, error: Error?) {
        statusLabel.text = "Status: Disconnected"
    }
    
    func serialDidReceiveString(_ message: String) {
        messageReceiveLabel.text = "Message Receive: \(message)"
    }
    
    func serialDidReceiveBytes(_ bytes: [UInt8]) {
        
    }
    
    func serialDidReceiveData(_ data: Data) {
        
    }
    
    func serialDidReadRSSI(_ rssi: NSNumber) {
        
    }
    
    func serialDidDiscoverPeripheral(_ bluetoothDevices: [BluetoothDevice]) {
        
    }
    
    func serialDidConnect(_ bluetoothDevice: BluetoothDevice) {
        statusLabel.text = "Status: Connected"
    }
    
    func serialDidFailToConnect(_ bluetoothDevice: BluetoothDevice, error: Error?) {
        
    }
    
    func serialIsReady(_ bluetoothDevice: BluetoothDevice) {
        
    }
    
    
}
