//
//  ContactsViewController.swift
//  Ch14 - Contact List
//
//  Created by user216619 on 9/19/22.
//

import UIKit
import CoreData
//AVFoundation = allows for customizable & powerful image solutions
import AVFoundation

class ContactsViewController: UIViewController, UITextFieldDelegate, DateControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var currentContact: Contact?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtAddress: UITextField!
    @IBOutlet weak var txtCity: UITextField!
    @IBOutlet weak var txtState: UITextField!
    @IBOutlet weak var txtZip: UITextField!
    @IBOutlet weak var txtCell: UITextField!
    @IBOutlet weak var txtPhone: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var lblBirthdate: UILabel!
    @IBOutlet weak var btnChange: UIButton!
    @IBOutlet weak var sgmtEditMode: UISegmentedControl!
    @IBOutlet weak var imgContactPicture: UIImageView!
    @IBOutlet weak var lblPhone: UILabel!
    @IBOutlet var settingsView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if currentContact != nil {
            txtName.text = currentContact!.contactName
            txtAddress.text = currentContact!.streetAddress
            txtCity.text = currentContact!.city
            txtState.text = currentContact!.state
            txtZip.text = currentContact!.zipCode
            txtPhone.text = currentContact!.phoneNumber
            txtCell.text = currentContact!.cellNumber
            txtEmail.text = currentContact!.email
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            if currentContact!.birthday != nil {
                lblBirthdate.text = formatter.string(from: currentContact!.birthday!)
            }
            if let imageData = currentContact?.image {
                imgContactPicture.image = UIImage(data: imageData)
            }
            let longPress = UILongPressGestureRecognizer.init(target: self, action: #selector(callPhone(gesture:)))
            lblPhone.addGestureRecognizer(longPress)
        }
        
        self.changeEditMode(self)
        
        let textFields: [UITextField] = [txtName, txtAddress, txtCity, txtState, txtZip,
                                         txtPhone, txtCell, txtEmail]
        for textfield in textFields {
            textfield.addTarget(self,
                                action: #selector(UITextFieldDelegate.textFieldShouldEndEditing(_:)),
                                for: UIControl.Event.editingDidEnd)
        }
    }
    
    func dateChanged(date: Date) {
        if currentContact == nil {
            let context = appDelegate.persistentContainer.viewContext
            currentContact = Contact(context: context)
        }
        currentContact?.birthday = date
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        lblBirthdate.text = formatter.string(from: date)
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if currentContact == nil {
            let context = appDelegate.persistentContainer.viewContext
            currentContact = Contact(context: context)
        }
        currentContact?.contactName = txtName.text
        currentContact?.streetAddress = txtAddress.text
        currentContact?.city = txtCity.text
        currentContact?.state = txtState.text
        currentContact?.zipCode = txtZip.text
        currentContact?.cellNumber = txtCell.text
        currentContact?.phoneNumber = txtPhone.text
        currentContact?.email = txtEmail.text
        return true
    }
    
    @objc func saveContact() {
        appDelegate.saveContext()
        sgmtEditMode.selectedSegmentIndex = 0
        changeEditMode(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        //Disposes of any resources that can be recreated
    }
    
    @IBAction func changeEditMode(_ sender: Any) {
        let textFields: [UITextField] = [txtName, txtAddress, txtCity, txtState, txtZip, txtPhone, txtCell, txtEmail]
        
        if sgmtEditMode.selectedSegmentIndex == 0 {
            for textField in textFields {
                textField.isEnabled = false
                textField.borderStyle = UITextField.BorderStyle.none
            }
            btnChange.isHidden = true
            navigationItem.rightBarButtonItem = nil
        }
        else if sgmtEditMode.selectedSegmentIndex == 1 {
            for textField in textFields {
                textField.isEnabled = true
                textField.borderStyle = UITextField.BorderStyle.roundedRect
            }
            btnChange.isHidden = false
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,
                                                                target: self,
                                                                action: #selector(self.saveContact))
        }
    }
    
    @IBAction func changePicture(_ sender: Any) {
        //checks to see if user has granted permission to use camera
        //if so, skip to else
        //if not, alert controller with 2 actions created & presented
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) !=
            AVAuthorizationStatus.authorized {
            
            //Camera not authorized
            let alertController = UIAlertController(title: "Camera Access Denied", message: "In order to take pictures, you need to allow the app to access the camera in the Settings.", preferredStyle: .alert)
            //action for opening settings created
            let actionSettings = UIAlertAction(title: "Open Settings",
                                               style: .default) {
                action in
                self.openSettings()
            }
            let actionCancel = UIAlertAction(title: "Cancel",
                                             style: .cancel,
                                             handler: nil)
            alertController.addAction(actionSettings)
            alertController.addAction(actionCancel)
            present(alertController, animated: true, completion: nil)
        }
        else
        {   // Already Authorized
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                let cameraController = UIImagePickerController()
                cameraController.sourceType = .camera
                cameraController.cameraCaptureMode = .photo
                cameraController.delegate = self
                cameraController.allowsEditing = true
                self.present(cameraController, animated: true, completion: nil)
            }
        }
    }
    
    func openSettings() {
        //retrieves UIApplicationSettingsURLString = used to pass open method to launch Settings app for app
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            //checks to see if device is running at least iOS 10
            if #available(iOS 10.0, *) {
                //if so, calls open method with settingsURL to open app's settings
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            } else {
                //if not, versions before iOS 10 use method openURL
                UIApplication.shared.openURL(settingsUrl)
            }
        }
    }
    
    @objc func callPhone(gesture: UILongPressGestureRecognizer) {
        //.began = only called once for entire gesture press & only true first time through method
        if gesture.state == .began {
            let number = txtPhone.text
            //makes sure number isn't blank
            if number!.count > 0 { //Don't call blank numbers
                //NSURL = holds phone number to call by concatenating protocol prefix (teleprompt://) with number from txtPhone field
                let url = NSURL(string: "telprompt://\(number!)")
                //calls number
                UIApplication.shared.open(url! as URL, options: [:], completionHandler: nil)
                //prints status message to console
                print("Calling Phone Number: \(url!)")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.registerKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.unregisterKeyboardNotifications()
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage {
            imgContactPicture.contentMode = .scaleAspectFit
            imgContactPicture.image = image
            if currentContact == nil {
                let context = appDelegate.persistentContainer.viewContext
                currentContact = Contact(context: context)
            }
             currentContact?.image = image.jpegData(compressionQuality: 1.0)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(ContactsViewController.keyboardDidShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ContactsViewController.keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardDidShow(notification: NSNotification) {
        let userInfo: NSDictionary = notification.userInfo! as NSDictionary
        let keyboardInfo = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue
        let keyboardSize = keyboardInfo.cgRectValue.size
        
        //Get existing contentInset for scrollView & set bottom property to be height of keyboard
        //Content Inset = distance of ScrollView's contents from ScrollView's edges
        var contentInset = self.scrollView.contentInset
        contentInset.bottom = keyboardSize.height
        
        self.scrollView.contentInset = contentInset
        self.scrollView.scrollIndicatorInsets = contentInset
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        var contentInset = self.scrollView.contentInset
        contentInset.bottom = 0
        
        self.scrollView.contentInset = contentInset
        self.scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "segueContactDate"){
            let dateController = segue.destination as! DateViewController
            dateController.delegate = self
        }
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
