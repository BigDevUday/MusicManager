//
//  MusicViewTVC.swift
//  AudioPlayerManagerBIGOH
//
//  Created by Uday on 27/09/22.
//

import UIKit

class MusicViewTVC: UITableViewCell {
    
    let titleLabel = UILabel()

    override func awakeFromNib() {
        super.awakeFromNib()
        addSubViewsAndlayout()
    }
    
    func addSubViewsAndlayout() {
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false //Must use
        NSLayoutConstraint.activate([titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 12.0), titleLabel.heightAnchor.constraint(equalToConstant: 30),titleLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 12), titleLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: 12)])
    }

}
