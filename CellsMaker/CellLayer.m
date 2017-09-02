//
//  CellLayer.m
//  CellMaker
//
//  Created by ooyama on 2014/08/07.
//
//  このアプリでアニメーションを要する部品の大元となる細胞クラス
//  アニメーションを必要とするがios6に対応するためにSpriteKitを使用せずにCALayerを使用

#import "CellLayer.h"

@implementation CellLayer

- (id)init
{
    self = [super init];
    if (self) {
        //細胞
        _cellImage = [CALayer new];
        _cellImage.frame = CGRectMake(self.bounds.size.width + 22, self.bounds.size.height + 4, 50, 50);
        _cellImage.contents = (id)[UIImage imageNamed:@"cell.png"].CGImage;
        _cellImage.backgroundColor = [UIColor lightGrayColor].CGColor;
        _cellImage.name = @"CELLIMAGE";
        
        //細胞マスク(矩形指定した場合の周りにはみ出す部分まで色が変わらないように)
        CALayer *_cellMask = [CALayer new];
        _cellMask.frame = CGRectMake(self.bounds.size.width + 22, self.bounds.size.height + 4, 50, 50);
        _cellMask.contents = (id)[UIImage imageNamed:@"cell_mask.png"].CGImage;
        _cellMask.name = @"CELLMASK";
        
        [self addSublayer:_cellImage];
        [self addSublayer:_cellMask];
    }
    return self;
}

@end
