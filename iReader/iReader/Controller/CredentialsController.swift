//
//  CredentialsController.swift
//  iReader
//
//  Created by MAS on 3/23/19.
//  Copyright © 2019 PrintAndGo. All rights reserved.
//

import UIKit
import Alamofire
import CommonCrypto
import Foundation
import Security
import PDFKit

class CredentialsController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var pdfUIImageView: UIImageView!
    
    var pdfView = PDFView()
    
    var passportString : String = ""
    var csrf: String = ""
//    var hashDownloaded : String = ""
    var hashDecrypted : String = ""
    var fileHash : Data? = nil // App's computed hash value for the downloaded file
    let pdfDownloadURL = baseURL + "/read"
    let hashDownloadURL = baseURL + "/readhash"
    var hashValuesMatch: Bool = false
    
    let publicKeyStr = "-----BEGIN RSA PUBLIC KEY-----\nMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAoI+u5a4B88SloIrElifFWMF2MaqqgjHlQOx/ho92qMcx1AcS3M6wVfxE73otxCsH9iZblyKZsbFVsUx1GCLgNXBlck9Q7ZQqlxLX/EMKzVV7yVXstlgmPSl0TiT6VnBZTXvSNz/n0fYFf+OelT5gBkjQ1+EQfBUR1LYkF6Q9mdGvfCjJ8apYSw5X/15F6mw0PGF4IZMK0l5I/i1CyYx2bfsgtEFbIoi5vYw6M4utSEQw7iq3bg4WzfowVYwGyoGKyqm+bBiuHGz9DwW/iSjBqB4G2H60uDHYbsXjSQZluGJBxXfmdzxWIEZpvDKVDkhGnQnjRLTQ1a4MiLJpZsBi7lL4LENuJhsBxTGAfOotgPP8EgCPijHUVHMZhNLhr8V3TGeA9WXcr+dUgbMvrMXJiapH1tUnd8ZidfouB9fk0V9kJ1D2GYg0XSJiIQ/wYYMTn29eomlatlYk9FkeW3d0JlTO2F6NPFzLK9c3Kv4OEDZ7eY2bkBvIJGxcjC3qWWFowoj/pKHjXmjF3On0l2uvT5aiRnPEj5VdIOd9aMegTjCG6SblqDnU3eKPt64XVapW+yszpTwUtU3AvTytRq7nDHPu2zPjoQ9anXqfLJAngyOPOw0O7y54FGbMwAizr+O10YNByG11/wfjv7PXr1a2m8+DBWBEz2d/sZXGvcbbNFMCAwEAAQ==\n-----END RSA PUBLIC KEY-----"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(pdfView)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        
        let pdfURL = downloadPassport()
        compareHashValues()
        if hashValuesMatch { // Only if the hash values of the pdf file match
            if let document = PDFDocument(url: pdfURL) {
                pdfView.document = document
            }
            pdfView.autoScales = true
            pdfView.maxScaleFactor = 4.0
            pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
            pdfView.frame = pdfUIImageView.frame
            pdfUIImageView.autoresizesSubviews = true
        }
        
    }
    
    
    @objc func appMovedToBackground() {
        performSegue(withIdentifier: "logout", sender: self)
    }
    

    func compareHashValues() {
        
        let parameters: [String: String] = [
            "_csrf": self.csrf,
            "uuid" : self.passportString
        ]
        
        AF.request(self.hashDownloadURL, method: .get, parameters: parameters)
            .response { response in
                switch response.result {
                case .success:
                    if let responseData = response.data, let utf8Text = String(data: responseData, encoding: .utf8) {
                        if utf8Text.contains("NullPointerException") {
                            print(utf8Text)
                            self.pdfView.document = nil
                            createAlert(title: "Invalid QR", message: "Couldn't review a PDF file for the corresponding QR code", sender: self)
                        }
                       self.hashValuesMatch = self.decryptHash(hashDownloaded: utf8Text)
                    }
                case .failure( _):
                    createAlert(title: "Connection Failure", message: "Cannot connect to the server", sender: self)
                }
        }
    }
    
    
    /*
     This is the main mechanism for checking the digital signature and also the hash value of the file. The padding and encryption can vary and Swift requires more precise clarifications than Java. The encryption and decryption attributes should match for a successful application run.
     */
    func decryptHash(hashDownloaded: String) -> Bool {
        
        let keyString = publicKeyStr.replacingOccurrences(of: "-----BEGIN RSA PUBLIC KEY-----\n", with: "").replacingOccurrences(of: "\n-----END RSA PUBLIC KEY-----", with: "")

        let keyData = Data(base64Encoded: keyString)!

        let importedKey:[NSObject:NSObject] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits: NSNumber(value: 4096),
            kSecReturnPersistentRef: true as NSObject
        ]
    
        let message = fileHash!.hexEncodedString()
        let blockSize = SecKeyGetBlockSize(importedKey as! SecKey)
        var messageEncrypted = Array(hashDownloaded.utf8)
//        var messageEncrypted = [UInt8](repeating: 0, count: blockSize)
        let messageEncryptedSize = blockSize
//
        var status: OSStatus!
//
//        status = SecKeyEncrypt(importedKey!, SecPadding.PKCS1, message, message.characters.count, &messageEncrypted, &messageEncryptedSize)
//
//        if status != noErr {
//            print("Encryption Error!")
//            print(status!)
//            return false
//        }
        
//        print(messageEncrypted)
//        let data = Data(NSData(bytes: &messageEncrypted, length: messageEncryptedSize))
//        print(data.hexEncodedString())
//        print(fileHash!.base64EncodedData())
//        print("----")
//        print(importedKey)
//        print("----")
//        print(data.hexEncodedString())
//        print(hashDownloaded)
//        print(fileHash?.hexEncodedString())
    
        var messageDecrypted = [UInt8](repeating: 0, count: blockSize)
        var messageDecryptedSize = blockSize
        
        status = SecKeyDecrypt(importedKey as! SecKey, SecPadding.PKCS1, &messageEncrypted, messageEncryptedSize, &messageDecrypted, &messageDecryptedSize)
        
        if status != noErr {
            print("Decryption Error!")
            print(status)
            return false
        }
        
        print(fileHash!.hexEncodedString())
        print(NSString(bytes: &messageDecrypted, length: messageDecryptedSize, encoding: String.Encoding.utf8.rawValue)!)
        
        return true
    }
    
    
    func downloadPassport() ->URL {
        let parameters: [String: String] = [
            "_csrf": self.csrf,
            "uuid" : self.passportString
        ]
        
        let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory)
        
        AF.download(
            pdfDownloadURL,
            method: .get,
            parameters: parameters,
            encoding: URLEncoding.default,
            headers: nil,
            to: destination).downloadProgress(closure: { (progress) in
                //progress closure
            }).response(completionHandler: { (DefaultDownloadResponse) in
                //here you able to access the DefaultDownloadResponse
                //result closure
            })
        
        //Getting a list of the docs directory
        let docURL = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last) as NSURL?
        
        //put the contents in an array.
        let contents = try? (FileManager.default.contentsOfDirectory(at: docURL! as URL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles))
        //print the file listing to the console
       
        let fileURL = findFileURL(urlList: contents.unsafelyUnwrapped)
        fileHash = sha512(url: fileURL)
        //fileHash = fileHashed.hexEncodedString()
        return fileURL
        //print(fileHash)

    }

    func findFileURL(urlList: [URL]) -> URL {
        for fileURL in urlList {
            let fileURLStr = fileURL.absoluteString
//            print("FILE URL: ")
//            print(fileURLStr)
            if fileURLStr.contains("Passport.pdf"){
                return fileURL
            }
        }
        createAlert(title: "Failed Download", message: "Passport.pdf file couldn't be obtained", sender: self)
//        createAlert(title: "Failed Download", message: "Passport.pdf file couldn't be obtained")
        return URL(string:"error")!
        
    }
    
    func sha512(url: URL) -> Data {
        do {
            let bufferSize = 1024 * 1024
            // Open file for reading:
            let file = try FileHandle(forReadingFrom: url)
            defer {
                file.closeFile()
            }
            // Create and initialize SHA512 context:
            var context = CC_SHA512_CTX()
            CC_SHA512_Init(&context)
            
            // Read up to `bufferSize` bytes, until EOF is reached, and update SHA256 context:
            while autoreleasepool(invoking: {
                // Read up to `bufferSize` bytes
                let data = file.readData(ofLength: bufferSize)
                if data.count > 0 {
                    data.withUnsafeBytes {
                        _ = CC_SHA512_Update(&context, $0, numericCast(data.count))
                    }
                    // Continue
                    return true
                } else {
                    // End of file
                    return false
                }
            }) { }
            
            // Compute the SHA256 digest:
            var digest = Data(count: Int(CC_SHA512_DIGEST_LENGTH))
            digest.withUnsafeMutableBytes {
                _ = CC_SHA512_Final($0, &context)
            }
            
            return digest
        } catch {
            print(error)
            return Data()
        }
    }

//    func createAlert(title: String, message: String) {
//        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
//
//        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action) in
//            alert.dismiss(animated: true, completion: nil)
//        }))
//
//        self.present(alert, animated: true, completion: nil)
//    }
//
//    @IBAction func backButtonPressed(_ sender: Any) {
//        self.dismiss(animated: true, completion: nil)
//    }
    
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
    
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hexString.index(hexString.startIndex, offsetBy: i*2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
}
