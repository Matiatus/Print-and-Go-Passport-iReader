//
//  ReadPassportController.swift
//  iReader
//
//  Created by MAS on 3/23/19.
//  Copyright © 2019 PrintAndGo. All rights reserved.
//

import UIKit
import AVFoundation
import CryptorRSA
import SystemConfiguration

class ReadPassportController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var cameraViewWindow: UIImageView!
    @IBOutlet weak var readPassportButton: UIButton!
    private let session = AVCaptureSession()
    var csrf: String = ""
    var passportString: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        
        session.startRunning()
        // Do any additional setup after loading the view, typically from a nib.
        readPassportButton.isHidden = true
        initiateCameraSession()
//
//        passportString = "4037a2e7-fe17-4a14-b5b7-e328b0131389"
//        performSegue(withIdentifier: "showCredentials", sender: self)
    }
    
    @objc func appMovedToBackground() {
        performSegue(withIdentifier: "logout", sender: self)
    }
    
    @IBAction func readPassportPressed(_ sender: Any) {
        self.viewDidLoad()
    }
    
    func initiateCameraSession() {
        //SOURCE : https://gist.github.com/shinjism/95a432ef535a06a15fd438c241526cf1, Japanese comments are google-translated to English
        
        //Creating session
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                                mediaType: .video,
                                                                position: .back)
        
        // Get the device that corresponds to the wide angle camera, video, rear camera
        let devices = discoverySession.devices
        
        //　Use the first obtained device among the applicable devices
        if let backCamera = devices.first {
            do {
                // Settings for using the image of the rear camera to read the QR code
                let deviceInput = try AVCaptureDeviceInput(device: backCamera)
                
                if self.session.canAddInput(deviceInput) {
                    self.session.addInput(deviceInput)
                    
                    // Settings for detecting a QR code from the rear camera image
                    let metadataOutput = AVCaptureMetadataOutput()
                    
                    if self.session.canAddOutput(metadataOutput) {
                        self.session.addOutput(metadataOutput)
                        
                        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                        metadataOutput.metadataObjectTypes = [.qr]
                        
                        // Create a layer to display the rear camera image on the screen
                        let previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
                        previewLayer.frame = cameraViewWindow.layer.bounds
                        previewLayer.videoGravity = .resizeAspectFill
                        cameraViewWindow.layer.addSublayer(previewLayer)
                        
                        // Start reading
                        self.session.startRunning()
                    }
                }
            } catch {
                print("Error occured while creating video device input: \(error)")
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        for metadata in metadataObjects as! [AVMetadataMachineReadableCodeObject] {
            // Check if it is data of QR code
            if metadata.type != .qr { continue }
            
            //
            if metadata.stringValue == nil { continue }
            
            /*
             Note that the timing of the end / resume timing of reading to gonyogonyo using the QR code acquired here is different depending on the application, so the following is an example of opening the website linked to the QR code with Safari
             */
            
            //            // Check if it is a URL
            //            if let url = URL(string: metadata.stringValue!) {
            //                // End reading
            //                self.session.stopRunning()
            //                // Open the URL linked to the QR code in Safari
            //                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            //                break
            //            }
            
            //createAlert(title: "QR CODE DETECTED", message: metadata.stringValue!)
            passportString = metadata.stringValue!
            readPassportButton.isHidden = false
            
            if Reachability.isConnectedToNetwork(){
                performSegue(withIdentifier: "showCredentials", sender: self)
            }else{
                createAlert(title: "Error", message: "Internet Connection not Available!",sender: self)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCredentials" {
            session.stopRunning()
            let credentialsController = segue.destination as! CredentialsController
            credentialsController.csrf = self.csrf
            credentialsController.passportString = self.passportString
        } 
    }
}

public class Reachability {
    
    class func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        /* Only Working for WIFI
         let isReachable = flags == .reachable
         let needsConnection = flags == .connectionRequired
         
         return isReachable && !needsConnection
         */
        
        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)
        
        return ret
        
    }
}
