//
//  OboLayer.h
//  CellMaker
//
//  Created by ooyama on 2014/08/07.
//
//  大元となる細胞クラスを継承したキャラクタークラス
//  アニメーションを必要とするがios6に対応するためにSpriteKitを使用せずにCALayerを使用

#import <QuartzCore/QuartzCore.h> //CoreAnimation用フレームワーク

@interface OboLayer : CALayer

@property (strong, nonatomic) CALayer *rightHand; //右手
@property (strong, nonatomic) CALayer *leftHand;  //左手

- (void)setBuhin; //各部品の生成メソッド
- (void)openCloseAnimation:(int)beganEnded; //両腕開閉アニメーション
@end
