//
//  ViewController.swift
//  ConcurrencyExample
//
//  Created by Alonso Guevara del Campo on 5/18/18.
//  Copyright © 2018 alonso. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private let topImageView = UIImageView()
    private let bottomImageView = UIImageView()
    private var images = [UIImage]()
    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.text = "Work in progresss..."
        label.textAlignment = NSTextAlignment.center
        label.adjustsFontSizeToFitWidth = true
        
        return label
    }()
    
    /// Measure
    var startTime = Date().timeIntervalSince1970
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        [topImageView, bottomImageView, timeLabel].enumerated().forEach { offset, imageView in
            view.addSubview(imageView)
            let topOffset: CGFloat = 50
            imageView.frame =  CGRect(x: 0, y: (view.bounds.maxY / 3) * CGFloat(offset) + topOffset, width: view.bounds.width, height: view.bounds.width * (2 / 3))
        }
        
        fetchImages()
    }
    
    ///
    /// Change the concurrent value on chromaKeyRemove to see the difference between
    /// executing the task in a serial way vs doing it in parallel with GCD's
    /// concurrentPerform dispatchQueue.
    ///
    private func processImages() {
        startTime = Date().timeIntervalSince1970
        let processedImages = images.compactMap { $0.chromaKeyRemove(concurrent: true) }
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.topImageView.image = processedImages.first!
            strongSelf.bottomImageView.image = processedImages.last!
            strongSelf.timeLabel.text = "Time taken: \(Date().timeIntervalSince1970 - strongSelf.startTime) seconds!"
        }
    }
    
    private func fetchImages() {
        let hugeCromaImageURLs = [URL(string: "https://d2v9y0dukr6mq2.cloudfront.net/video/thumbnail/tnv5NWN/female-reporter-on-chroma-key-background-4k_rtawr3k7x_thumbnail-full01.png")!,
                                  URL(string: "https://d2v9y0dukr6mq2.cloudfront.net/video/thumbnail/MPaEbz-/chroma-key-video-of-weatherman-presenting-weather-forecast-on-tv_4efohjmae__F0002.png")!]
        
        let dispatchGroup = DispatchGroup()
        
        hugeCromaImageURLs.forEach({
            dispatchGroup.enter()
            URLSession.shared.dataTask(with: $0) { [weak self] data, response, error in
                defer { dispatchGroup.leave() }
                guard error == nil, let imageData = data, let uiImage = UIImage(data: imageData) else { return }
                
                self?.images.append(uiImage)
            }.resume()
        })
        
        dispatchGroup.notify(queue: DispatchQueue.global()) { [weak self] in
            self?.processImages()
        }

    }
}
