//
//  PlayerViewController.swift
//


extension OOOoyalaPlayerViewController {

//    override public func viewWillDisappear(animated: Bool) {
//        super.viewWillDisappear(animated)
//        self.player = nil
//    }

    override public func shouldAutorotate() -> Bool {
        return true
    }

    override public func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Landscape
    }

}
