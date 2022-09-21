//
//  SettingsViewController.swift
//  Ch14 - Contact List
//
//  Created by user216619 on 9/19/22.
//

import UIKit
import CoreMotion

class SettingsViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet var settingsView: UIView!
    @IBOutlet weak var swAscending: UISwitch!
    @IBOutlet weak var pckSortField: UIPickerView!
    @IBOutlet weak var lblBattery: UILabel!
        
    let sortOrderItems: Array<String> = ["contactName", "city", "birthday"]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        pckSortField.dataSource = self;
        pckSortField.delegate = self;
        
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(self.batteryChanged), name: UIDevice.batteryStateDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.batteryChanged), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        self.batteryChanged()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //set the UI based on values in UserDefaults
        let settings = UserDefaults.standard
        swAscending.setOn(settings.bool(forKey: Constants.kSortDirectionAscending), animated: true)
        let sortField = settings.string(forKey: Constants.kSortField)
        var i = 0
        for field in sortOrderItems {
            if field == sortField {
                pckSortField.selectRow(i, inComponent: 0, animated: false)
            }
            i += 1
        }
        pckSortField.reloadComponent(0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let device = UIDevice.current
        print("Device Info:")
        print("Name: \(device.name)")
        print("Model: \(device.model)")
        print("System Name: \(device.systemName)")
        print("System Version: \(device.systemVersion)")
        print("Identifier: \(device.identifierForVendor!)")
        
        //switch statement identifies all the ways device can be oriented
        let orientation: String
        switch device.orientation {
        case .faceDown:
            orientation = "Face Down"
        case .landscapeLeft:
            orientation = "Landscape Left"
        case .portrait:
            orientation="Portrait"
        case .landscapeRight:
            orientation = "Landscape Right"
        case .faceUp:
            orientation = "Face Up"
        case .portraitUpsideDown:
            orientation = "Portrait Upside Down"
        case .unknown:
            orientation = "Unknown Orientation"
        @unknown default:
            fatalError()
        }
        print("Orientation: \(orientation)")
        self.startMotionDetection()
    }
        
    @IBAction func sortDirectionChanged(_ sender: Any) {
        let settings = UserDefaults.standard
        settings.set(swAscending.isOn, forKey: Constants.kSortDirectionAscending)
        //Forces synchronization saving
        settings.synchronize()
    }
    
    //notifications about changes in battery level occur only when shifts by full percentage point
    @objc func batteryChanged(){
        let device = UIDevice.current
        var batteryState: String
        switch(device.batteryState){
        case .charging:
            batteryState = "+"
        case .full:
            batteryState = "!"
        case .unplugged:
            batteryState = "-"
        case .unknown:
            batteryState = "?"
        @unknown default:
            fatalError()
        }
        let batteryLevelPercent = device.batteryLevel * 100
        let batteryLevel = String(format: "%.0f%%", batteryLevelPercent)
        let batteryStatus = "\(batteryLevel) (\(batteryState))"
        lblBattery.text = batteryStatus
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        UIDevice.current.isBatteryMonitoringEnabled = false
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.motionManager.stopAccelerometerUpdates()
    }
    
    func startMotionDetection(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let mManager = appDelegate.motionManager
        if mManager.isAccelerometerAvailable {
            //sets update interval in seconds (20 times per second)
            mManager.accelerometerUpdateInterval = 0.05
            mManager.startAccelerometerUpdates(to: OperationQueue.main) {
                (data: CMAccelerometerData?, error: Error?) in
                self.updateLabel(data: data!)
            }
        }
    }
    
    func updateLabel(data: CMAccelerometerData){
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        let tabBarHeight = self.tabBarController?.tabBar.frame.height
        //moveFactor = multiplier that decides how far label is moved with each update; changing value makes it move faster/slower
        let moveFactor:Double = 15.0
        var rect = lblBattery.frame
        //calculates next position along x-axis by multiplying moveFactor with acceleration along x-axis and adding to original x-axis location of label
        //accelerometer data is reported between -1 and 1, 0 = rest
        let moveToX = Double(rect.origin.x) + data.acceleration.x * moveFactor
        let moveToY = Double(rect.origin.y + rect.size.height) - (data.acceleration.y * moveFactor)
        //keeps label from falling off screen
        let maxX = Double(settingsView.frame.size.width - rect.width)
        let maxY = Double(settingsView.frame.size.height - tabBarHeight!)
        let minY = Double(rect.size.height + statusBarHeight)
        //checks to see if new position will move label off screen along x-axis
        //if not, updates x value for position of label
        if(moveToX > 0 && moveToX < maxX){
            rect.origin.x += CGFloat(data.acceleration.x * moveFactor)
        }
        //repeat ^ for y axis
        if(moveToY > minY && moveToY < maxY){
            rect.origin.y -= CGFloat(data.acceleration.y * moveFactor);
        }
        //updates display by animating movement from old to new location
        //setting duration & delay to 0 = animation carried out immediately
        UIView.animate(withDuration: TimeInterval(0),
                       delay: TimeInterval(0),
                       //specifies how animation is done; here, it's moved small distance at a time
                       options: UIView.AnimationOptions.curveEaseInOut,
                       //specify code that will run to update display
                       animations: {self.lblBattery.frame = rect},
                       completion: nil)
    }

    // MARK: UIPickerViewDelegate Methods
        
    // Returns # of 'columns' to display.
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
        
    // Returns # of rows in the picker
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sortOrderItems.count
    }
        
    //Sets the value that is shown for each row in the picker
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int)
            -> String? {
                return sortOrderItems[row]
    }
        
    //If the user chooses from the pickerview, it calls this function;
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let sortField = sortOrderItems[row]
        let settings = UserDefaults.standard
        settings.set(sortField, forKey: Constants.kSortField)
        settings.synchronize()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
