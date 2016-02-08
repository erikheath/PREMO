//
//  Player.swift
//

import Foundation

public class Player: OOOoyalaPlayer {

    override public func nextVideo() -> Bool {
        self.setPlayheadTime(self.playheadTime() + 15.0)
        return false
    }

    override public func previousVideo() -> Bool {
        self.setPlayheadTime(self.playheadTime() - 15.0)
        return false
    }

}
