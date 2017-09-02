//
//  ViewController.h
//  CellsMaker
//
//  Created by ooyama on 2014/08/06.
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h> //CoreAnimation用フレームワーク
#import <AudioToolbox/AudioToolbox.h> //効果音用フレームワーク
#import <Social/Social.h>//twitter連携用フレームワーク
#import "CellLayer.h" //細胞レイヤークラス
#import "OboLayer.h"  //キャラクターレイヤークラス
#import "UIOutlineLabel.h" //中抜き文字表示用クラス
#import "NADView.h" //Nend用クラス


@interface ViewController : UIViewController<NADViewDelegate>

@end
