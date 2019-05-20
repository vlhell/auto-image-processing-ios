//
//  ViewController.swift
//  Work
//
//  Created by Vladislav Bogdanov on 15/05/2019.
//  Copyright © 2019 Vladislav Bogdanov. All rights reserved.
//

import UIKit
import CoreImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    struct Filter {
        var filterName: String?
        var filterEffectValue: Any?
        var filterEffectValueName: String?
        
        init(filterName: String, filterEffectValue: Any?, filterEffectValueName: String?) {
            self.filterName = filterName
            self.filterEffectValue = filterEffectValue
            self.filterEffectValueName = filterEffectValueName
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewResult: UIImageView!
    @IBOutlet weak var sceneLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    let model = ImageClassifier()

    @IBAction func chooseImage(_ sender: Any) {
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        
        let actionSheet = UIAlertController(title: "", message: "Choose a source", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action:UIAlertAction) in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePickerController.sourceType = .camera
                self.present(imagePickerController, animated: true, completion: nil)
            } else {
                print("Camera is not available")
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action:UIAlertAction) in
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        
        imageView.image = image
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func analyze(_ sender: Any) {
        if let imageToAnalyze = imageView?.image {
            if let sceneString = getScene(image: imageToAnalyze) {
                sceneLabel.text = sceneString
            }
        }
        
    }
    
    func getScene(image:UIImage) -> String? {
        if let pixelBuffer = ImageProcessor.pixelBuffer(forImage: image.cgImage!) {
            guard let scene = try? model.prediction(image: pixelBuffer)
                else {
                    fatalError("Unexpected runtime error")
                }
            
            return scene.classLabel
        }
        
        return nil
    }
    
    
    @IBAction func upgradeImage(_ sender: Any) {
        guard let imageToUpgrade = imageView?.image else {
            fatalError("Unexpected runtime error")
        }
        
        var filter = Filter(filterName: "", filterEffectValue: nil, filterEffectValueName: nil)
        var scene: String?
        
        scene = sceneLabel.text
        
        if scene == "HumanFace" {
            filter.filterName = "CILinearToSRGBToneCurve"
        } else if scene == "SunFlower" {
            filter.filterName = "CIHueAdjust"
            filter.filterEffectValue = 0.99
            filter.filterEffectValueName = kCIInputAngleKey
        } else {
            filter.filterName = "CIPhotoEffectTransfer"
        }
            
        imageViewResult?.image = makeDifference(inputImage: imageToUpgrade, inputFilter: filter)
    }
    
    func makeDifference(inputImage: UIImage, inputFilter: Filter) -> UIImage? {
        guard let cgImage = inputImage.cgImage
        else {
            return nil
        }
        
        let context = CIContext()
        let image = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: inputFilter.filterName!)
        
        filter?.setValue(image, forKey: kCIInputImageKey)
        
        if let inputFilterValue = inputFilter.filterEffectValue,
            let inputFilterValueName = inputFilter.filterEffectValueName {
            filter?.setValue(inputFilterValue, forKey: inputFilterValueName)
        }
        
        var outputImage: UIImage?
        
        if let output = filter?.value(forKey: kCIOutputImageKey) as? CIImage,
            let cgImageResult = context.createCGImage(output, from: output.extent) {
            outputImage = UIImage(cgImage: cgImageResult)
        }
        
        return outputImage
    }
    
}

