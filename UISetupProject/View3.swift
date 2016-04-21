//
//  View3.swift
//  UISetupProject
//
//  Created by Willy Zhang on 2016-04-17.
//  Copyright © 2016 Willy Zhang. All rights reserved.
//

import UIKit

class View3: UIViewController {

    @IBOutlet weak var view3ImageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func showImage(image: UIImage) {
        self.view3ImageView.image = image
        self.view3ImageView.hidden = false
    }

    func hideImage() {
        self.view3ImageView.hidden = true
    }
}
