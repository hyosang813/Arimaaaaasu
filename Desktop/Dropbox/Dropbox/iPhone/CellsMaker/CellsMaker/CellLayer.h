//
//  CellLayer.h
//  CellMaker
//
//  Created by ooyama on 2014/08/07.
//
//  このアプリでアニメーションを要する部品の大元となる細胞クラス
//  アニメーションを必要とするがios6に対応するためにSpriteKitを使用せずにCALayerを使用

#import <QuartzCore/QuartzCore.h> //CoreAnimation用フレームワーク

@interface CellLayer : CALayer
@property (strong, nonatomic) CALayer *cellImage;
@end
