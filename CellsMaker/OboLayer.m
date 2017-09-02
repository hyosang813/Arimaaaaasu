//
//  OboLayer.m
//  CellMaker
//
//  Created by ooyama on 2014/08/07.
//
//

#import "OboLayer.h"
enum {CLOSE, OPEN}; //両腕開閉アニメーション用

@implementation OboLayer
{
    //開閉状態フラグ
    int openClose;
}

//各部品のセット
- (void)setBuhin
{
    //本体
    CALayer *hontai = [CALayer new];
    hontai.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    hontai.contents = (id)[UIImage imageNamed:@"character.png"].CGImage;
    hontai.name = @"OBOBO";
    
    //右手
    _rightHand = [CALayer new];
    _rightHand.frame = CGRectMake(self.bounds.size.width - 65, self.bounds.size.height / 5, 64, 220);
    _rightHand.contents = (id)[UIImage imageNamed:@"migi.png"].CGImage;
    _rightHand.transform = CATransform3DRotate(_rightHand.transform, M_PI / 6, 0, 0, 1);
    _rightHand.anchorPoint = CGPointMake(0.5, 1.0);
    _rightHand.name = @"RIGHT_HAND";
    
    //左手
    _leftHand = [CALayer new];
    _leftHand.frame = CGRectMake(5, self.bounds.size.height / 5, 64, 220);
    _leftHand.contents = (id)[UIImage imageNamed:@"hidari.png"].CGImage;
    _leftHand.transform = CATransform3DRotate(_leftHand.transform, -(M_PI / 6), 0, 0, 1);
    _leftHand.anchorPoint = CGPointMake(0.5, 1.0);
    _leftHand.name = @"LEFT_HAND";
    
    //開閉フラグの初期化(最初は開いてる)
    openClose = OPEN;
    
    //配置 self(自分自身レイヤー)の上に本体と右腕と左腕のレイヤーをそれぞれ配置
    [self addSublayer:_rightHand];
    [self addSublayer:_leftHand];
    [self addSublayer:hontai];
}

//両腕開閉アニメーション
- (void)openCloseAnimation:(int)beganEnded
{
    //閉じてる状態ではそれ以上閉じないし、開いてる状態ではそれ以上開かない
    if ( (beganEnded == CLOSE && openClose == CLOSE) || (beganEnded == OPEN && openClose == OPEN) ) return;
    
    //開閉ディスパッチ
    float leftAngle = 0.0;
    float rightAngle = 0.0;
    
    if (beganEnded == CLOSE) {
        rightAngle = -(M_PI / 6);
        leftAngle = M_PI / 6;
        openClose = CLOSE;
    } else {
        rightAngle = M_PI / 6;
        leftAngle = -(M_PI / 6);
        openClose = OPEN;
    }
    
    _rightHand.transform = CATransform3DRotate(_rightHand.transform, rightAngle, 0, 0, 1);
    _leftHand.transform = CATransform3DRotate(_leftHand.transform, leftAngle, 0, 0, 1);

}

@end
