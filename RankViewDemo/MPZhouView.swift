//
//  MPZhouView.swift
//  RankViewDemo
//
//  Created by Maple on 2017/8/4.
//  Copyright © 2017年 Maple. All rights reserved.
//

import UIKit

protocol MPZhouViewProtocol {
    /// 显示在拖动轴上的数值
    var zhouText: String? { get }
}
class TestModel: MPZhouViewProtocol{
    var zhouText: String? {
        get {
            return dateStr
        }
    }
    var dateStr: String?
}

protocol MPZhouViewDelegate: NSObjectProtocol {
    /// 返回选中的开始，以及结束下标
    func zhouView(startIndex: Int?, endIndex: Int?)
}

class MPZhouView: UIView {
    // MARK: - Public
    /// 设置拖动轴的数据
    ///
    /// - Parameters:
    ///   - modelArr: 遵守MPZhouViewProtocol协议的模型数组
    ///   - totalCount: 拖动轴一共分为几等份
    func set(modelArr: Array<MPZhouViewProtocol>?, totalCount: Int) {
        self.modelArr = modelArr
        self.totalCount = totalCount
        layoutSubviews()
        if startCenterX == nil && endCenterX == nil && modelArr != nil && unit != nil {
            // 设置初始值
            startCenterX = zhouRect.minX
            endCenterX = zhouRect.minX + CGFloat(modelArr!.count) * unit!
            drawRange = (minX: startCenterX, maxX: endCenterX)
            // 遍历所有的Text，找出最宽的Text，从而得到一个符合所有Text的rectSize
            // 防止宽度改变导致的抖动
            var maxSize: CGSize = CGSize.zero
            for model in modelArr! {
                if let text = model.zhouText {
                    let size = text.size(font, width: zhouRect.width)
                    if size.width > maxSize.width {
                        maxSize = size
                    }
                }
            }
            maxSize = CGSize(width: maxSize.width + rectMargin, height: maxSize.height + rectMargin)
            popRectSize = maxSize
            // 计算下标
            calculateIndex()
        }
        setNeedsDisplay()
    }
    
    weak var delegate: MPZhouViewDelegate?
    /// 字体Font，默认为13
    var font: UIFont = UIFont.systemFont(ofSize: 13)
    /// “对话框"尖角的Size
    var arrowSize = CGSize(width: 10, height: 8)
    /// 红色三角形的边长
    var triangleLength: CGFloat = 15
    
    // MARK: - Property
    /// 遵守MPZhouViewProtocol协议模型
    fileprivate var modelArr: Array<MPZhouViewProtocol>?
    /// 一个单元的间距
    fileprivate var unit: CGFloat? {
        get {
            return zhouRect.width / CGFloat(totalCount)
        }
    }
    /// 一共分为几等分
    fileprivate var totalCount: Int = 0
    /// text内容Size距离矩形框的间距
    fileprivate let rectMargin: CGFloat = 5
    /// 拖动轴Rect
    fileprivate var zhouRect: CGRect!
    /// 拖动轴的左右间距
    fileprivate var zhouRectSpacex: CGFloat = 10
    /// 拖动轴的高度
    fileprivate let zhouH: CGFloat = 5
    /// 拖动轴填充色
    fileprivate let zhouBgColor: UIColor = UIColor.colorWithHexString("f2f2f2")
    /// 拖动轴边界颜色
    fileprivate let zhouBorderColor: UIColor = UIColor.gray
    /// 触摸点
    fileprivate var touchPoint: CGPoint?
    /// 线宽
    fileprivate let lineWidth: CGFloat = 1
    
    /// 文本View最底的y坐标值
    fileprivate var textBottomY: CGFloat {
        get {
            return zhouRect.minY - 5
        }
    }
    /// 可以拖动的区域
    fileprivate var drawRange: (minX: CGFloat, maxX: CGFloat)?
    /// “对话框”的宽度
    fileprivate var popRectSize: CGSize?
    /// 起点拖动轴中点坐标
    fileprivate var startCenterX: CGFloat!
    /// 起点下标
    fileprivate var startIndex: Int?
    /// 终点拖动轴终点坐标
    fileprivate var endCenterX: CGFloat!
    /// 终点下标
    fileprivate var endIndex: Int?
    /// 标记是否正在操作起点拖轴
    fileprivate var isStartZhou: Bool = true
    
    // MARK: - Init
    init(totalCount: Int) {
        self.totalCount = totalCount
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.clear
        let pan = UIPanGestureRecognizer(target: self, action: #selector(MPZhouView.panAction(gesture:)))
        self.addGestureRecognizer(pan)
    }
    
    convenience init(totalCount: Int, zhouRectSpacex: CGFloat) {
        self.init(totalCount: totalCount)
        self.zhouRectSpacex = zhouRectSpacex
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        zhouRect = CGRect(x: zhouRectSpacex, y: self.frame.height * 0.5 - 0.5 * zhouH, width: self.frame.width - 2 * zhouRectSpacex, height: zhouH)
    }
    
    // MARK: - Action
    @objc func panAction(gesture: UIGestureRecognizer) {
        guard let _ = modelArr else {
            return
        }
        guard let range = drawRange else {
            return
        }
        var point = gesture.location(in: self)
        // 防止越界
        if point.x < range.minX {
           point.x = range.minX
        }
        if point.x > range.maxX {
            point.x = range.maxX
        }
        // 判断对哪个拖动轴进行操作
        if gesture.state == .began {
            if (fabs(point.x - startCenterX) / fabs(point.x - endCenterX)) < 1 || point.x < startCenterX {
                // 距离起点比较近
                isStartZhou = true
            }else {
                // 距离终点比较近
                isStartZhou = false
            }
        }
        if isStartZhou {
            // 距离起点比较近
            if point.x > endCenterX {
                startCenterX = endCenterX
            }else{
                startCenterX = point.x
            }
        }else {
            if point.x < startCenterX {
                endCenterX = startCenterX
            }else {
                endCenterX = point.x
            }
        }
        calculateIndex()
        delegate?.zhouView(startIndex: startIndex, endIndex: endIndex)
        setNeedsDisplay()
    }
    
    /// 计算下标
    fileprivate func calculateIndex() {
        guard let datas = modelArr, let aUnit = unit else {
            return
        }
        var startIndex = Int((startCenterX - zhouRect.minX ) / aUnit)
        var endIndex = Int((endCenterX - zhouRect.minX ) / aUnit)
        
        if endIndex >= datas.count {
            endIndex = datas.count - 1
        }
        if startIndex >= datas.count {
            startIndex = datas.count - 1
        }
        self.startIndex = startIndex
        self.endIndex = endIndex
    }
    
    // MARK: - Draw
    override func draw(_ rect: CGRect) {
        // 画拖动轴
        let rectPath = UIBezierPath.init(rect: zhouRect)
        zhouBgColor.setFill()
        rectPath.fill()
        zhouBorderColor.setStroke()
        rectPath.stroke()
        
        guard let datas = modelArr, let aRectSize = popRectSize, let stIndex = startIndex, let edIndex = endIndex else {
            return
        }
        guard let startText = datas[stIndex].zhouText, let endText = datas[edIndex].zhouText else {
            return
        }
        var startMinX: CGFloat = startCenterX - 0.5 * aRectSize.width
        // 起点拖动View的最大X
        var startMaxX: CGFloat = startMinX + aRectSize.width
        // 终点拖动View的最小X
        var endMinX: CGFloat = endCenterX - 0.5 * aRectSize.width
        var endMaxX: CGFloat = endMinX + aRectSize.width

        // 防止右边越界
        if endMinX + aRectSize.width > self.frame.width - lineWidth * 0.5 {
            endMaxX = self.frame.width - lineWidth * 0.5
            endMinX = endMaxX - aRectSize.width
        }
        // 防止左边越界
        if startMinX < 0.5 * lineWidth {
            startMinX = 0.5 * lineWidth
            startMaxX = startMinX + aRectSize.width
        }
        
        // 两个拖动轴相遇时
        if startMaxX > endMinX {
            // 计算偏移量
            let delta = startMaxX - endMinX
            endMinX  = endMinX + delta * 0.5
            startMinX = startMinX - delta * 0.5
            startMaxX = startMinX + aRectSize.width
            endMaxX = endMinX + aRectSize.width
            if startMaxX + aRectSize.width > self.frame.width - lineWidth * 0.5 {
                // 达到右边界
                endMaxX = self.frame.width - lineWidth * 0.5
                endMinX = endMaxX - aRectSize.width
                startMaxX = endMinX
                startMinX = startMaxX - aRectSize.width
            }else if endMinX - aRectSize.width < lineWidth * 0.5{
                // 到达左边界
                startMinX = lineWidth * 0.5
                startMaxX = startMinX + aRectSize.width
                endMinX = startMaxX
                endMaxX = endMinX + aRectSize.width
            }
        }
        // 绘制连接线
        let lineY: CGFloat = zhouRect.minY + zhouRect.height * 0.5
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: startCenterX, y: lineY))
        linePath.addLine(to: CGPoint(x: endCenterX, y: lineY))
        UIColor.red.setStroke()
        linePath.lineWidth = zhouH - 2
        linePath.stroke()
        
        // 绘制起点x轴
        drawPopText(text: startText, startX: startMinX, endX: startMaxX, centerX: startCenterX, rectSize: aRectSize)
        // 绘制终点x轴
        drawPopText(text: endText, startX: endMinX, endX: endMaxX, centerX: endCenterX, rectSize: aRectSize)
    }
    
    /// 画“对话框”的Text
    fileprivate func drawPopText(text: String, startX: CGFloat, endX: CGFloat, centerX: CGFloat, rectSize: CGSize) {
        let size = text.size(font, width: UIScreen.main.bounds.width)
        
        let path: UIBezierPath = UIBezierPath()
        let y3: CGFloat = textBottomY
        let y2: CGFloat = textBottomY - arrowSize.height
        let y1: CGFloat = y2 - rectSize.height
        let x1: CGFloat = startX
        
        let x2: CGFloat = centerX - arrowSize.width * 0.5
        let x3: CGFloat = centerX + arrowSize.width * 0.5
        let x4: CGFloat = endX

        // 绘制对话框
        path.lineWidth = lineWidth
        path.move(to: CGPoint(x: x1, y: y1))
        path.addLine(to: CGPoint(x: x1, y: y2))
        path.addLine(to: CGPoint(x: x2, y: y2))
        path.addLine(to: CGPoint(x: centerX, y: y3))
        path.addLine(to: CGPoint(x: x3, y: y2))
        path.addLine(to: CGPoint(x: x4, y: y2))
        path.addLine(to: CGPoint(x: x4, y: y1))
        path.close()
        UIColor.red.setStroke()
        path.stroke()
        
        let padding = (rectSize.width - size.width) * 0.5
        let textRect = CGRect(x: x1 + padding, y: y1 + 0.5 * rectMargin, width: size.width, height: size.height)
        let dic: [String: Any] = [NSForegroundColorAttributeName: UIColor.red, NSFontAttributeName: font]
        (text as NSString).draw(in: textRect, withAttributes: dic)
        
        // 绘制圆
        let center = CGPoint(x: centerX, y: zhouRect.minY + zhouRect.height * 0.5)
        let radius: CGFloat = zhouRect.height - 1
        let circlePath = UIBezierPath.init(arcCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true)
        circlePath.lineWidth = 1.5
        UIColor.white.setFill()
        circlePath.fill()
        UIColor.red.setStroke()
        circlePath.stroke()
        
        // 绘制三角形
        let trianglePath: UIBezierPath = UIBezierPath()
        let tY1: CGFloat = zhouRect.maxY + 5
        let tY2: CGFloat = triangleLength * (2 / 3) + tY1
        trianglePath.move(to: CGPoint(x: centerX, y: tY1))
        trianglePath.addLine(to: CGPoint(x: centerX - 0.5 * triangleLength, y: tY2))
        trianglePath.addLine(to: CGPoint(x: centerX + 0.5 * triangleLength, y: tY2))
        trianglePath.close()
        UIColor.red.setFill()
        trianglePath.fill()
    }
}

extension String {
    //自动算出字体空间大小
    func size(_ font:UIFont, width:CGFloat) -> CGSize {
        let size = CGSize(width: width, height: CGFloat(MAXFLOAT))
        let str = NSString(format: "%@", self)
        let dic = [NSFontAttributeName:font]
        return str.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: dic, context: nil).size
    }
}

extension UIColor {
    
    class func colorWithHexString (_ hex:String,alpha:CGFloat = 1.0) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString = (cString as NSString).substring(from: 1)
        }
        
        if (cString.lengthOfBytes(using: String.Encoding.utf8) != 6) {
            return UIColor.gray
        }
        
        let rString = (cString as NSString).substring(to: 2)
        let gString = ((cString as NSString).substring(from: 2) as NSString).substring(to: 2)
        let bString = ((cString as NSString).substring(from: 4) as NSString).substring(to: 2)
        
        var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
        Scanner(string: rString).scanHexInt32(&r)
        Scanner(string: gString).scanHexInt32(&g)
        Scanner(string: bString).scanHexInt32(&b)
        return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: alpha)
    }
}














