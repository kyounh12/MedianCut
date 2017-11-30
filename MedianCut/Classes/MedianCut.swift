
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
    private var numOfColor = 16
    
    func getColors(image: UIImage, numberOfColors: Int, completion: @escaping ([UIColor]) -> Void) {
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
            
            let resizedImage = self.resizeImage(image: image, targetSize: CGSize(width: 200, height: 200))
            
            let iPixels = self.initializePixelData(image: resizedImage)
            
            var colorTables: [UIColor] = []
            
            self.getColorTables(pixels: iPixels, colorTable: &colorTables, count: 0)
            
            colorTables = colorTables.uniqueColors
            
            completion(colorTables)
        }
    }
    
    private func getColorTables(pixels: [Pixel], colorTable: inout [UIColor], count: Int) {
        
        if count == Int(log2(Double(numOfColor))) {
            
            colorTable.append(getAverageColor(pixels: getDominantSorted(pixels: pixels)))
            return
        }
        
        let sortedPixels = getDominantSorted(pixels: pixels)
        
        let separatorIndex = sortedPixels.count / 2
        
        var front: [Pixel] = []
        var rear: [Pixel] = []
        
        for i in 0..<pixels.count {
            if i <= separatorIndex {
                front.append(pixels[i])
            } else {
                rear.append(pixels[i])
            }
        }
        
        let count = count + 1
        
        getColorTables(pixels: front, colorTable: &colorTable, count: count)
        getColorTables(pixels: rear, colorTable: &colorTable, count: count)
        
    }
    
    private func initializePixelData(image: UIImage) -> [Pixel] {
        
        let bmp = image.cgImage!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(bmp)
        
        var pixels: [Pixel] = []
        let row = image.size.width * image.scale
        let col = image.size.height * image.scale
        
        for i in 0..<Int(row) {
            for j in 0..<Int(col) {
                let pixelInfo: Int = ((Int(col) * Int(i)) + Int(j)) * 4
                let rgb = [CGFloat(data[pixelInfo+2]) / CGFloat(255), CGFloat(data[pixelInfo+1]) / CGFloat(255), CGFloat(data[pixelInfo]) / CGFloat(255)]
                let pixel = Pixel(rgb: rgb)
                pixels.append(pixel)
                
            }
        }
        
        return pixels
    }
    
    private func getDominantSorted(pixels: [Pixel]) -> [Pixel]{
        var pixels = pixels
        
        var rRange: (CGFloat,CGFloat) = (1,0)
        var gRange: (CGFloat,CGFloat) = (1,0)
        var bRange: (CGFloat,CGFloat) = (1,0)
        
        for pixel in pixels {
            rRange = (min(rRange.0, pixel.rgb[0]),max(rRange.1, pixel.rgb[0]))
            gRange = (min(gRange.0, pixel.rgb[1]),max(gRange.1, pixel.rgb[1]))
            bRange = (min(bRange.0, pixel.rgb[2]),max(bRange.1, pixel.rgb[2]))
        }
        
        let rangeTable = [(rRange.1 - rRange.0), (gRange.1 - gRange.0), (bRange.1 - bRange.0)]
        
        let dominantIndex = rangeTable.index(of: max(rangeTable[0], max(rangeTable[1], rangeTable[2])))!
        
        pixels.sort { (a, b) -> Bool in
            return (a.rgb[dominantIndex] > b.rgb[dominantIndex])
        }
        
        return pixels
    }
    
    private func getTrivialSorted(pixels: [Pixel]) -> [Pixel]{
        var pixels = pixels
        
        var rRange: (CGFloat,CGFloat) = (1,0)
        var gRange: (CGFloat,CGFloat) = (1,0)
        var bRange: (CGFloat,CGFloat) = (1,0)
        
        for pixel in pixels {
            rRange = (min(rRange.0, pixel.rgb[0]),max(rRange.1, pixel.rgb[0]))
            gRange = (min(gRange.0, pixel.rgb[1]),max(gRange.1, pixel.rgb[1]))
            bRange = (min(bRange.0, pixel.rgb[2]),max(bRange.1, pixel.rgb[2]))
        }
        
        let rangeTable = [(rRange.1 - rRange.0), (gRange.1 - gRange.0), (bRange.1 - bRange.0)]
        
        let dominantIndex = rangeTable.index(of: max(rangeTable[0], max(rangeTable[1], rangeTable[2])))!
        
        pixels.sort { (a, b) -> Bool in
            return (a.rgb[dominantIndex] < b.rgb[dominantIndex])
        }
        
        return pixels
    }
    
    private func getAverageColor(pixels: [Pixel]) -> UIColor {
        
        var r = CGFloat(0)
        var g = CGFloat(0)
        var b = CGFloat(0)
        
        for pixel in pixels {
            r += pixel.rgb[0]
            g += pixel.rgb[1]
            b += pixel.rgb[2]
        }
        
        r /= CGFloat(pixels.count)
        g /= CGFloat(pixels.count)
        b /= CGFloat(pixels.count)
        
        //        let ar = r
        //        let ag = g
        //        let ab = b
        //
        //        r = 0
        //        g = 0
        //        b = 0
        //
        //        for pixel in pixels {
        //            var diff = abs(pixel.rgb[0] - ar)
        //            diff += abs(pixel.rgb[1] - ag) + abs(pixel.rgb[2] - ab)
        //            var oDiff = abs(r - ar)
        //            oDiff += abs(g - ag) + abs(b - ab)
        //
        //            if diff < oDiff {
        //                r = pixel.rgb[0]
        //                g = pixel.rgb[1]
        //                b = pixel.rgb[2]
        //            }
        //        }
        
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
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    private struct Pixel{
        var rgb = Array.init(repeating: CGFloat(0), count: 3)
        //        var r: CGFloat
        //        var g: CGFloat
        //        var b: CGFloat
    }
    
    //    func minAndMax()-> {
    //
    //    }
    
    
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
        if abs(self.redValue - to.redValue) > 0.05 {
            return false
        }
        if abs(self.blueValue - to.blueValue) > 0.05 {
            return false
        }
        if abs(self.greenValue - to.greenValue) > 0.05 {
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
