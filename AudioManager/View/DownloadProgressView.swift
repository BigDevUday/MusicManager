
import UIKit


class DownloadProgressView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func resetPath(){
        self.removeFromSuperview()
    }
    
    var path: UIBezierPath = UIBezierPath()
    var shape = CAShapeLayer()

    func updatePath(progressPoint : Float){
        self.layer.sublayers?.forEach({ layer in
            layer.removeFromSuperlayer()
        })
        path.removeAllPoints()
        shape.removeFromSuperlayer()
        
        let getAngle = CGFloat(Float((Double.pi)) * 27/180 * progressPoint + Float(-Double.pi/2) )
  
        path.addArc(withCenter: CGPoint(x: self.frame.width/2, y: self.frame.height/2), radius: self.frame.height/2, startAngle: CGFloat(-Double.pi/2), endAngle: getAngle, clockwise: true)
        shape.path = path.cgPath

        shape.lineWidth = 2.0
        shape.strokeColor = UIColor.green.cgColor
        shape.fillColor = UIColor.clear.cgColor
        self.layer.addSublayer(shape)
    }
    
    
    
}

