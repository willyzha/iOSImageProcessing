//
//  View1.swift
//  UISetupProject
//
//  Created by Willy Zhang on 2016-04-17.
//  Copyright © 2016 Willy Zhang. All rights reserved.
//

import UIKit

class View1: UIViewController {

    @IBOutlet weak var threshold: UILabel!
    @IBOutlet weak var thresholdSlider: UISlider!
    @IBOutlet weak var searchSlider: UISegmentedControl!
    
    var thresholdPercent = Float()
    var view2 = View2()
    var selectedColor = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        thresholdSlider.value = thresholdSlider.maximumValue * 0.25 // Default to 25%
        let percentage = (thresholdSlider.value / thresholdSlider.maximumValue) * 100
        threshold.text = "\(percentage)%"
        thresholdPercent = percentage / 100
        selectedColor = searchSlider.selectedSegmentIndex
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func adjustThreshold(sender: AnyObject) {
        let percentage = (thresholdSlider.value / thresholdSlider.maximumValue) * 100
        adjustColourThreshold(percentage)
    }
    
    @IBAction func switchSearchSlider(sender: AnyObject) {
        selectedColor = searchSlider.selectedSegmentIndex
        view2.selectedColor = selectedColor
    }
    
    @IBAction func pressResetColourThreshold(sender: AnyObject) {
        thresholdSlider.value = thresholdSlider.maximumValue * 0.25
        let percentage = (thresholdSlider.value / thresholdSlider.maximumValue) * 100
        adjustColourThreshold(percentage)
    }
    
    func initView1(view: View2) {
        view2 = view
        view2.selectedColor = selectedColor
        view2.thresholdPercentage = thresholdPercent
    }
    
    func adjustColourThreshold(percentage: Float) {
        threshold.text = "\(percentage)%"
        thresholdPercent = percentage / 100
        print ("slide \(percentage)")
        view2.thresholdPercentage = thresholdPercent
    }    
}
