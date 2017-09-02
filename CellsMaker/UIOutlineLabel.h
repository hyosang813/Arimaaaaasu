//
//  UIOutlineLabel.h
//  CellMaker
//
//  Created by ooyama on 2014/08/07.
//
//  中抜き文字を表現する為のUILabelを継承したクラス
//  参考ページ：http://qiita.com/shzero5/items/249d01e48eb456e99e67

@import UIKit;

@interface UIOutlineLabel : UILabel

@property(nonatomic) UIColor *outlineColor;
@property(nonatomic) NSInteger outlineSize;

@end
