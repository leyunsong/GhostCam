//
//  MovieTableViewCell.swift
//  GhostCam
//
//  Created by Leyun Song on 16/1/7.
//  Copyright © 2016年 Leyun Song. All rights reserved.
//

import UIKit

class MovieTableViewCell: UITableViewCell {
    @IBOutlet weak var Preview: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var filePathLabel: UILabel!
    @IBOutlet weak var fileSizeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
