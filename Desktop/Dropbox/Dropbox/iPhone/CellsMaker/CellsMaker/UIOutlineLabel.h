//
//  UIOutlineLabel.h
//  CellMaker
//
//  Created by ooyama on 2014/08/07.
//
//  中抜き文字を表現する為のUILabelを継承したクラス
//

@import UIKit;

@interface UIOutlineLabel : UILabel

@property(nonatomic) UIColor *outlineColor;
@property(nonatomic) NSInteger outlineSize;

@end
