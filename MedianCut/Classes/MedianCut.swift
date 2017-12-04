
//
//  MedianCut.swift
//  MedianCut_Example
//
//  Created by 이준석 on 2017. 12. 1..
//  Copyright © 2017년 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

public class MedianCut {
    private var numOfColor = 256
    private var data: UnsafePointer<UInt8>!
    
    public static let instance = MedianCut()
    
    public func getColors(image: UIImage, numberOfColors: Int, completion: @escaping ([UIColor]) -> Void) {
        DispatchQueue.main.async {
            
            if numberOfColors < 16 {
                print("Need at least 16 colors")
                completion([])
            }
            
            if log2(Double(numberOfColors)) - Double(Int(log2(Double(numberOfColors)))) != 0 {
                print("number of colors must be an exponetial of 2")
                completion([])
            }
            
            self.numOfColor = numberOfColors
            
            let resizedImage = self.resizeImage(image: image, targetSize: CGSize(width: 100, height: 100))
            
            let bmp = resizedImage.cgImage!.dataProvider!.data
            self.data = CFDataGetBytePtr(bmp)
            
            var pointers: [Int] = []
            for i in 0..<Int(resizedImage.size.width * resizedImage.scale * resizedImage.size.height * resizedImage.scale) {
                pointers.append(i*4)
            }
            
            var colorTables: [UIColor] = []
            
            self.getColorTables(pointers: pointers, colorTable: &colorTables, count: 0)
            
            colorTables = colorTables.uniqueColors
            
            colorTables = colorTables.sorted(by: { (a, b) -> Bool in
                if a.hueValue == b.hueValue {
                    if a.brightnessValue == b.brightnessValue {
                        return a.saturationValue > b.saturationValue
                    } else {
                        return a.brightnessValue > b.brightnessValue
                    }
                } else {
                    return a.hueValue > b.hueValue
                }
            })
            
            completion(colorTables)
        }
    }
    
    private func getColorTables(pointers: [Int], colorTable: inout [UIColor], count: Int) {
        
        if count == Int(log2(Double(numOfColor))) {
            colorTable.append(getAverageColor(pointers: pointers))
            return
        }
        
        let sortedPointers = getDominantSorted(pointers: pointers)
        
        let separatorIndex = sortedPointers.count / 2
        
        let front = sortedPointers[..<separatorIndex]
        let rear = sortedPointers[separatorIndex...]
        
        
        let count = count + 1
        
        getColorTables(pointers: Array(front), colorTable: &colorTable, count: count)
        getColorTables(pointers: Array(rear), colorTable: &colorTable, count: count)
        
    }
    
    private func getDominantSorted(pointers: [Int]) -> [Int]{
        var pointers = pointers
        
        var rRange = (255,0)
        var gRange = (255,0)
        var bRange = (255,0)
        
        for pointer in pointers {
            rRange = (min(rRange.0, Int(data[pointer + 2])),max(rRange.1, Int(data[pointer + 2])))
            gRange = (min(gRange.0, Int(data[pointer + 1])),max(gRange.1, Int(data[pointer + 1])))
            bRange = (min(bRange.0, Int(data[pointer])),max(bRange.1, Int(data[pointer])))
        }
        
        let rangeTable = [(bRange.1 - bRange.0), (gRange.1 - gRange.0), (rRange.1 - rRange.0)]
        
        let dominantIndex = rangeTable.index(of: max(rangeTable[0], max(rangeTable[1], rangeTable[2])))!
        
        pointers.sort { (a, b) -> Bool in
            return data[a+dominantIndex] > data[b+dominantIndex]
        }
        
        return pointers
    }

    
    private func getAverageColor(pointers: [Int]) -> UIColor {
        
        
        var r = CGFloat(0)
        var g = CGFloat(0)
        var b = CGFloat(0)
        
        for pointer in pointers {
            r += CGFloat(data[pointer + 2])
            g += CGFloat(data[pointer + 1])
            b += CGFloat(data[pointer])
        }
        
        r = r/CGFloat(pointers.count)/255
        g = g/CGFloat(pointers.count)/255
        b = b/CGFloat(pointers.count)/255
        
        
        return UIColor(red: r, green: g, blue: b, alpha: 1)
        
    }
    
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio,height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y:0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    
}

extension UIColor {
    var redValue: CGFloat{ return CIColor(color: self).red }
    var greenValue: CGFloat{ return CIColor(color: self).green }
    var blueValue: CGFloat{ return CIColor(color: self).blue }
    var alphaValue: CGFloat{ return CIColor(color: self).alpha }
    var hueValue: CGFloat{
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return h
    }
    var saturationValue: CGFloat{
        
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return s
        
        
    }
    var brightnessValue: CGFloat{
        
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return b
        
        
    }
    
    func isSimilar(to: UIColor) -> Bool {
        if abs(self.redValue - to.redValue) > 0.2 {
            return false
        }
        if abs(self.blueValue - to.blueValue) > 0.2 {
            return false
        }
        if abs(self.greenValue - to.greenValue) > 0.2 {
            return false
        }
        
        return true
    }
}

extension Array where Element:UIColor {
    var uniqueColors: [UIColor] {
        var set = Set<UIColor>() //the unique list kept in a Set for fast retrieval
        var arrayOrdered = [UIColor]() //keeping the unique list of elements but ordered
        for value in self {
            if !set.contains(where: { (color) -> Bool in
                if value.isSimilar(to: color) {
                    return true
                } else {
                    return false
                }
            }) {
                set.insert(value)
                arrayOrdered.append(value)
            }
        }
        
        return arrayOrdered
    }
}
