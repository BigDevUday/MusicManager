//
//  MusicView.swift
//  AudioPlayerManagerBIGOH
//
//  Created by Uday on 23/09/22.
//

import Foundation
import UIKit

protocol MusicViewDelegate : AnyObject {
    func playTheMusic()
}

class MusicView : UIViewController {
    
    static var shared = MusicView()
    weak var delegate : MusicViewDelegate?
    open var musicList = [String]() {
        didSet {
            print(musicList)
            tableView.reloadData()
        }
    }
    
    fileprivate var MainView = UIView()
    fileprivate var navigationView = UIView()
    fileprivate var musicBottomView = UIView()
    fileprivate var currentItemNameLabel = UILabel()
    fileprivate var musicLabel = UILabel()
    fileprivate var playButton = UIButton()
    fileprivate var tableView = UITableView()

    open func setUpView(view : UIView){
        let bounds = view.bounds
        MainView = UIView(frame: bounds)
        MainView.backgroundColor = .white
        setUpTableView()
        MainView.addSubview(tableView)
        MainView.addSubview(setUpNavigationBar(bounds: bounds))
        MainView.addSubview(setUpBottomMusicBar(bounds: bounds))
        setUpTableViewConstraint()
        view.addSubview(MainView)
    }

    
    func setUpNavigationBar(bounds:CGRect)-> UIView{
        navigationView.frame = CGRect(x: bounds.minX, y: bounds.minY+44, width: bounds.width, height: 60)
        navigationView.backgroundColor = .gray
        navigationView.setLabelInCenter(label: currentItemNameLabel, LabelText: "Music Player", FontType: UIFont.preferredFont(forTextStyle: .headline), textColor: .red)
        return navigationView
    }
    
        
    func setUpBottomMusicBar(bounds:CGRect)->UIView{
        musicBottomView.frame = CGRect(x: bounds.minX, y: bounds.maxY-80, width: bounds.width, height: 80)
        musicBottomView.backgroundColor = .yellow
        musicBottomView.addSubview(playButton)
        musicBottomView.addSubview(musicLabel)
        setUpConstraintForMusicBar()
        setUpPlayButton()
        playButton.addTarget(self, action: #selector(pressed), for: .touchUpInside)
        return musicBottomView
    }
    
    func setUpConstraintForMusicBar(){
        NSLayoutConstraint.activate([playButton.topAnchor.constraint(equalTo: musicBottomView.topAnchor, constant: 10),playButton.bottomAnchor.constraint(equalTo: musicBottomView.bottomAnchor, constant: 10),playButton.rightAnchor.constraint(equalTo: musicBottomView.rightAnchor, constant: 10),playButton.heightAnchor.constraint(equalToConstant: 30),playButton.widthAnchor.constraint(equalToConstant: 30)])
    }
    
    func setUpPlayButton(){
        playButton.frame = CGRect(x: 0.0, y: 0.0, width: 50, height: 50)
        playButton.setImage(UIImage.init(named: "pause"), for: .normal)
        playButton.addTarget(self, action: #selector(pressed), for: .touchUpInside)
    }
    
    @objc func pressed() {
        delegate?.playTheMusic()
        if playButton.isSelected{
            if playButton.tag == 1{
                playButton.setImage(UIImage.init(named: "play"), for: .normal)
            }else{
                playButton.setImage(UIImage.init(named: "pause"), for: .normal)
            }
        }
    }

    
    func setUpTableView(){
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib.init(nibName: "MusicViewTVC", bundle: nil), forCellReuseIdentifier: "MusicViewTVC")
    }
    
    func setUpTableViewConstraint(){
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([tableView.topAnchor.constraint(equalTo: navigationView.bottomAnchor, constant: 0),tableView.leftAnchor.constraint(equalTo: MainView.leftAnchor), tableView.bottomAnchor.constraint(equalTo: musicBottomView.topAnchor), tableView.rightAnchor.constraint(equalTo: MainView.rightAnchor)])
    }
    
}

extension UIView {
    
    func setLabelInCenter(label:UILabel,LabelText:String, FontType: UIFont, textColor : UIColor){
        label.frame = CGRect(x: self.bounds.midX-self.bounds.width/4, y: self.bounds.midY-self.bounds.height/3, width: self.bounds.width/2, height: self.bounds.height/1.5)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = LabelText
        label.font = FontType
        label.textColor = textColor
        self.addSubview(label)
    }
    
    func buttonInCenter(button:UIButton,ButtonText:String, FontType: UIFont, textColor : CGColor){
        button.frame = CGRect(x: self.bounds.midX-self.bounds.width/4, y:self.bounds.midY-self.bounds.height/3, width: self.bounds.width/2, height:self.bounds.height/1.5)
        button.layer.backgroundColor = textColor
        button.setTitle(ButtonText, for: .normal)
        self.addSubview(button)
    }
    
    func setLabelInCenter(label:UILabel){
        self.addSubview(label)
    }
}
    
extension MusicView : UITableViewDelegate, UITableViewDataSource{

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        musicList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MusicViewTVC") as! MusicViewTVC
        cell.titleLabel.text = musicList[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }

}
    

