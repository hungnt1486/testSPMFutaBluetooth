//
//  ViewController.swift
//  Checkbluetooth
//
//  Created by mac on 20/09/2022.
//

import UIKit
import FutaBluetooth

class ViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    
    var bluetoothController: FutaBluetoothController!
    var bluetoothDevices = [BluetoothDevice]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
       // let stringTest = "$$$CHOTCA|&tab:210712789;9998888&G=1;106363392;10466710;0;0&C= 1;3980;0;0;12;3;0;2;133814190822&C=2;4440;4;4;14;3;0;2;404514190822|2 48###"
        //let testModel =  try ResultChotcaModel(message: stringTest)
        //print("== test model: \(testModel)")
        bluetoothController = FutaBluetoothController.shared
        bluetoothController.delegate = self
        bluetoothController.setAutoReconnect(auto: true)
        bluetoothController.startScan()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bluetoothController.delegate = self
    }
    
    @IBAction func buttonScanTouch() {
        bluetoothController.stopScan()
        bluetoothController.startScan()
    }

}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bluetoothDevices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let bluetoothDevice = bluetoothDevices[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: "cell") {
            cell.textLabel?.text = bluetoothDevice.name
            return cell
        }
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.textLabel?.text = bluetoothDevice.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let deviceSelected = bluetoothDevices[indexPath.row]
        bluetoothController.connect(bluetoothDevice: deviceSelected)
    }
    
    
}

extension ViewController: FutaBluetoothDelegate {
    func bluetoothDidReceiveError(error: BleError) {
        print("== error: \(error.localizedDescription)")
    }
    
    func bluetoothDidReceiveRead2(result: [ResultReadModel]?, isReady: Bool) {
        
    }
    
    func bluetoothDidReceiveRead1(result: [ResultReadModel]?, isReady: Bool) {
        
    }
    
    func bluetoothDidReceiveACK(command: BLECommand, ack: ResultACKModel) {
        
    }
    
    func bluetoothDidReceiveViewChotca(viewChotca: ResultChotcaModel?, isReady: Bool) {
        
    }
    
    func bluetoothDidReceiveChotca(chotca: ResultChotcaModel) {
        
    }
    
    func bluetoothDidReceiveSyncResult(result: ResultCommandSyncModel) {
        
    }
    
    func serialDidChangeState() {
        
    }
    
    func serialDidDisconnect(_ bluetoothDevice: BluetoothDevice, error: Error?) {
        
    }
    
    func serialDidReceiveString(_ message: String) {
        
    }
    
    func serialDidReceiveBytes(_ bytes: [UInt8]) {
        
    }
    
    func serialDidReceiveData(_ data: Data) {
        
    }
    
    func serialDidReadRSSI(_ rssi: NSNumber) {
        
    }
    
    func serialDidDiscoverPeripheral(_ bluetoothDevices: [BluetoothDevice]) {
        self.bluetoothDevices = bluetoothDevices
        tableView.reloadData()
    }
    
    func serialDidConnect(_ bluetoothDevice: BluetoothDevice) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        if let connectedVC = storyBoard.instantiateViewController(withIdentifier: "ConnectedScreen") as? ConnectedScreen {
            connectedVC.bluetoothController = bluetoothController
            navigationController?.pushViewController(connectedVC, animated: true)
        }
    }
    
    func serialDidFailToConnect(_ bluetoothDevice: BluetoothDevice, error: Error?) {
        
    }
    
    func serialIsReady(_ bluetoothDevice: BluetoothDevice) {
        
    }
    
    
}

