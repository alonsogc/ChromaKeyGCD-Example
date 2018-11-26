//
//  UIImage+.swift
//  ConcurrencyExample
//
//  Created by Alonso Guevara del Campo on 11/26/18.
//  Copyright © 2018 alonso. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    struct ARGB {
        let alpha: UInt32
        let red: UInt32
        let green: UInt32
        let blue: UInt32
    }
    
    func chromaKeyRemove(concurrent: Bool) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        
        var pixelData = pixelBuffer(from: cgImage)
        replaceGreen(buffer: &pixelData, concurrent: concurrent)
        
        let chromaContext = CGContext(data: &pixelData, width: cgImage.width, height: cgImage.height, bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: cgImage.bytesPerRow, space: cgImage.colorSpace!, bitmapInfo: cgImage.bitmapInfo.rawValue)
        
        guard let chromaCgImage = chromaContext?.makeImage() else { return nil }
        
        return UIImage(cgImage: chromaCgImage)
    }
    
    private func pixelBuffer(from cgImage: CGImage) -> [UInt32] {
        let dataSize = cgImage.width * cgImage.height * 4
        var pixelData = [UInt32](repeating: 0, count: Int(dataSize))
        
        let context = CGContext(data: &pixelData, width: cgImage.width, height: cgImage.height, bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: cgImage.bytesPerRow, space: cgImage.colorSpace!, bitmapInfo: cgImage.bitmapInfo.rawValue)
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        
        return pixelData
    }
    
    private func replaceGreen(buffer: inout [UInt32], concurrent: Bool) {
        if concurrent {
            ///
            /// Play with the iterations values, the greater the value the better, since it tries to fill
            /// idle fragments in the threads.
            ///
            let iterations = 100
            let chunkSize = buffer.count / iterations

            DispatchQueue.concurrentPerform(iterations: iterations) { iteration in

                for offset in iteration*chunkSize..<(iteration*chunkSize + chunkSize) {
                    let element = buffer[offset]
                    
                    let argb = ARGB(alpha: (element & 0xFF000000) >> 24, red: (element & 0x00FF0000) >> 16, green: (element & 0x0000FF00) >> 8, blue: element & 0x000000FF)
                    if argb.red < 2, argb.green > 253, argb.blue < 2 {
                        /// Assign the blue value for this pixel
                        buffer[offset] = 0x00FF0000
                    }
                }
            }
        } else {
            buffer.enumerated().forEach { (offset, element) in
                
                let argb = ARGB(alpha: (element & 0xFF000000) >> 24, red: (element & 0x00FF0000) >> 16, green: (element & 0x0000FF00) >> 8, blue: element & 0x000000FF)
                if argb.red < 2, argb.green > 253, argb.blue < 2 {
                    /// Assign the blue value for this pixel
                    buffer[offset] = 0x00FF0000
                }
            }
        }
    }

}
