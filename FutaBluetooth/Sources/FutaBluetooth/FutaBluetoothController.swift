//
//  ScanBluetoothController.swift
//  FutaBluetooth
//
//  Created by mac on 19/09/2022.
//

import Foundation
import CoreBluetooth


// Delegate functions
public protocol FutaBluetoothDelegate {
    
    func serialDidChangeState()
    
    // ** Optionals **
    
    /// Called when a peripheral disconnected
    func serialDidDisconnect(_ bluetoothDevice: BluetoothDevice, error: Error?)
    
    /// Called when a message is received
    func serialDidReceiveString(_ message: String)
    
    /// Called when a message is received
    func serialDidReceiveBytes(_ bytes: [UInt8])
    
    /// Called when a message is received
    func serialDidReceiveData(_ data: Data)
    
    /// Called when the RSSI of the connected peripheral is read
    func serialDidReadRSSI(_ rssi: NSNumber)
    
    /// Called when a new peripheral is discovered while scanning. Also gives the RSSI (signal strength)
    func serialDidDiscoverPeripheral(_ bluetoothDevices: [BluetoothDevice])
    
    /// Called when a peripheral is connected (but not yet ready for cummunication)
    func serialDidConnect(_ bluetoothDevice: BluetoothDevice)
    
    /// Called when a pending connection failed
    func serialDidFailToConnect(_ bluetoothDevice: BluetoothDevice, error: Error?)
    
    /// Called when a peripheral is ready for communication
    func serialIsReady(_ bluetoothDevice: BluetoothDevice)
    
    
    func bluetoothDidReceiveRead1(result: [ResultReadModel]?, isReady: Bool)
    func bluetoothDidReceiveRead2(result: [ResultReadModel]?, isReady: Bool)
    
    func bluetoothDidReceiveACK(command: BLECommand, ack: ResultACKModel)
    
    func bluetoothDidReceiveViewChotca(viewChotca: ResultChotcaModel?, isReady: Bool)
    
    func bluetoothDidReceiveChotca(chotca: ResultChotcaModel)
    
    func bluetoothDidReceiveSyncResult(result: ResultCommandSyncModel)
    
    func bluetoothDidReceiveError(error: BleError)
    
}


public class FutaBluetoothController: NSObject {
    
    public static var shared: FutaBluetoothController = {
        let instance = FutaBluetoothController()
        return instance
    }()
    
    private var bluetoothDevices = [BluetoothDevice]()
    
    private var centralManager: CBCentralManager!
    
    public var delegate: FutaBluetoothDelegate?
    
    /// The connected peripheral (nil if none is connected)
   public var connectedPeripheral: BluetoothDevice?
    
    /// The peripheral we're trying to connect to (nil if none)
    var pendingPeripheral: BluetoothDevice?
    
    /// The characteristic we need to write to, of the connectedPeripheral
   // weak var writeCharacteristic: CBCharacteristic?
    
    var isReady: Bool {
        get {
            return centralManager.state == .poweredOn &&
                connectedPeripheral != nil &&
            connectedPeripheral?.writeCharacteristic != nil
        }
    }
    
    private var isAutoReconnect = false
    
    private var autoConnectBluetoothDevice: BluetoothDevice?
    private var autoReconnectUUID: String?
    
    /// Required Write Type (selected automatically)
    private var writeType = CBCharacteristicWriteType.withResponse
    private var timerUpdateDiscoverPeripheral: Timer?
    private var autoReconnectTimer: Timer?
    
    /// Always use this to initialize an instance
    override init() {
        super.init()
       centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global(qos: .default))
    }
    
    public func setAutoReconnect(auto: Bool) {
        isAutoReconnect = auto
        if !isAutoReconnect {
            autoReconnectUUID = nil
            self.autoReconnectTimer?.invalidate()
        } else {
            // autoReconnectUUID = connectedPeripheral?.peripheral.identifier.uuidString
           autoReconnectUUID = autoConnectBluetoothDevice?.peripheral.identifier.uuidString
            if connectedPeripheral == nil {
                stopScan()
                startScan()
            }
        }
    }
    
    public func startScan() {
        guard centralManager.state == .poweredOn else { return }
        
        // start scanning for peripherals with correct service UUID
        let options = [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        let uuids: [CBUUID]? = Constant.serviceUUID
        centralManager.scanForPeripherals(withServices: uuids, options: options)
        
        // retrieve peripherals that are already connected
        // see this stackoverflow question http://stackoverflow.com/questions/13286487
        let peripherals = centralManager.retrieveConnectedPeripherals(withServices: Constant.serviceUUID)
        for peripheral in peripherals {
            let bluetoothDevice = BluetoothDevice(peripheral: peripheral)
            bluetoothDevices.append(bluetoothDevice)
        }
        DispatchQueue.main.async {
            self.timerUpdateDiscoverPeripheral =  Timer.scheduledTimer(timeInterval: 1.0,
                                                                  target: self,
                                                                       selector: #selector(self.discoverPeripheralInterval),
                                                                  userInfo: nil,
                                                                  repeats: true)
        }
        
    }
    
    public func stopScan() {
        centralManager.stopScan()
        bluetoothDevices.removeAll()
        timerUpdateDiscoverPeripheral?.invalidate()
        
        DispatchQueue.main.async {
            self.delegate?.serialDidDiscoverPeripheral(self.bluetoothDevices)
        }
        
    }
    
    public func connect(bluetoothDevice: BluetoothDevice) {
        timerUpdateDiscoverPeripheral?.invalidate()
        centralManager.stopScan()
       // bluetoothDevice.peripheral.delegate = self
        pendingPeripheral = bluetoothDevice
        centralManager.connect(bluetoothDevice.peripheral)
        if isAutoReconnect {
            autoReconnectUUID = bluetoothDevice.peripheral.identifier.uuidString
        }
        
        
    }
    
    public func disconnect() {
        if let p = connectedPeripheral {
            centralManager.cancelPeripheralConnection(p.peripheral)
        } else if let p = pendingPeripheral {
            centralManager.cancelPeripheralConnection(p.peripheral)
        }
    }
    
    public func sendCommandToBluetoothDevice(command: BLECommand) {
        guard isReady else { return }
        connectedPeripheral?.sendCommand(command: command)
    }
    
    
    //MARK: private
    private func reconnect() {
        DispatchQueue.main.async {
            if self.isAutoReconnect {
                self.autoReconnectTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                    self?.startScan()
                }
            }
        }
    }
    
    @objc private func discoverPeripheralInterval() {
        DispatchQueue.main.async {
            self.delegate?.serialDidDiscoverPeripheral(self.bluetoothDevices)
        }
        
    }
    
}


extension FutaBluetoothController: CBCentralManagerDelegate {
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // just send it to the delegate
        
        debugPrint("== didDiscover: \(peripheral)")
        
        // auto reconnect
        if let autoReconnectUUID = autoReconnectUUID, isAutoReconnect {
            if peripheral.identifier.uuidString == autoReconnectUUID {
                let bluetoothDevice = BluetoothDevice(peripheral: peripheral)
                connect(bluetoothDevice: bluetoothDevice)
                return
            }
        }
        
        // connect manual
        if let i = bluetoothDevices.firstIndex(where: ({ $0.peripheral.identifier == peripheral.identifier })) {
            bluetoothDevices[i].rssi = RSSI
            bluetoothDevices[i].lastUpdate = Date()
        } else {
            let bluetoothDevice = BluetoothDevice(peripheral: peripheral)
            bluetoothDevices.append(bluetoothDevice)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // set some stuff right
        let bluetoothDevice = BluetoothDevice(peripheral: peripheral)
        pendingPeripheral = nil
        connectedPeripheral = bluetoothDevice
        autoConnectBluetoothDevice = bluetoothDevice
        bluetoothDevices.removeAll()
        // send it to the delegate
        DispatchQueue.main.async {
            self.delegate?.serialDidConnect(bluetoothDevice)
        }
        
       
        debugPrint("== didConnect: \(peripheral.name)")
        bluetoothDevice.delegate = self
        bluetoothDevice.discoverServices(services: Constant.serviceUUID)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        // send it to the delegate
        if let connectedPeripheral = connectedPeripheral {
            DispatchQueue.main.async {
                self.delegate?.serialDidDisconnect(connectedPeripheral, error: error)
            }
        }
        connectedPeripheral = nil
        pendingPeripheral = nil
        debugPrint("== didDisconnectPeripheral: \(peripheral)")
        reconnect()
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        pendingPeripheral = nil
        if isAutoReconnect {
            reconnect()
            return
        }
        // just send it to the delegate
        let bluetoothDevice = BluetoothDevice(peripheral: peripheral)
        DispatchQueue.main.async {
            self.delegate?.serialDidFailToConnect(bluetoothDevice, error: error)
        }
        debugPrint("== didFailToConnect: \(peripheral)")
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // note that "didDisconnectPeripheral" won't be called if BLE is turned off while connected
        connectedPeripheral = nil
        pendingPeripheral = nil
        
        // send it to the delegate
        DispatchQueue.main.async {
            self.delegate?.serialDidChangeState()
        }
        debugPrint("== centralManagerDidUpdateState: \(central.state.rawValue)")
        switch central.state {
        case .poweredOn:
            debugPrint("== Peripheral Is Powered On.")
        case .unsupported:
            debugPrint("== Peripheral Is Unsupported.")
        case .unauthorized:
            debugPrint("== Peripheral Is Unauthorized.")
        case .unknown:
            debugPrint("== Peripheral Unknown")
        case .resetting:
            debugPrint("== Peripheral Resetting")
        case .poweredOff:
            debugPrint("== Peripheral Is Powered Off.")
        @unknown default:
            debugPrint("== Error")
        }
        
        if centralManager.state != .poweredOn {
          
        } else {
          
            stopScan()
            startScan()
           
        }
    }
}

extension FutaBluetoothController: BluetoothDeviceDelegate {
    func bluetoothDidReceiveError(error: BleError) {
        DispatchQueue.main.async {
            self.delegate?.bluetoothDidReceiveError(error: error)
        }
    }
    
    
    func bluetoothDidReceiveRead2(result: [ResultReadModel]?, isReady: Bool) {
        DispatchQueue.main.async {
            self.delegate?.bluetoothDidReceiveRead2(result: result, isReady: isReady)
        }
    }
    
    
    func bluetoothDidReceiveRead1(result: [ResultReadModel]?, isReady: Bool) {
        DispatchQueue.main.async {
            self.delegate?.bluetoothDidReceiveRead1(result: result, isReady: isReady)
        }
    }
    
    func bluetoothDidReceiveACK(command: BLECommand, ack: ResultACKModel) {
        DispatchQueue.main.async {
            self.delegate?.bluetoothDidReceiveACK(command: command, ack: ack)
        }
    }
    
    func bluetoothDidReceiveViewChotca(viewChotca: ResultChotcaModel?, isReady: Bool) {
        DispatchQueue.main.async {
            self.delegate?.bluetoothDidReceiveViewChotca(viewChotca: viewChotca, isReady: isReady)
        }
    }
    
    func bluetoothDidReceiveChotca(chotca: ResultChotcaModel) {
        DispatchQueue.main.async {
            self.delegate?.bluetoothDidReceiveChotca(chotca: chotca)
        }
    }
    
    func bluetoothDidReceiveSyncResult(result: ResultCommandSyncModel) {
        DispatchQueue.main.async {
            self.delegate?.bluetoothDidReceiveSyncResult(result: result)
        }
    }
    
    func bluetoothDeviceIsReady(bluetoothDevice: BluetoothDevice) {
        DispatchQueue.main.async {
            self.delegate?.serialIsReady(bluetoothDevice)
        }
    }
    
    func bluetoothDidReceiveMessage(message: String) {
        debugPrint("== bluetoothDidReceiveMessage: \(message)")
        DispatchQueue.main.async {
            self.delegate?.serialDidReceiveString(message)
        }
    }
    
    
}
