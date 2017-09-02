//
//  UIOutlineLabel.m
//  CellMaker
//
//  Created by ooyama on 2014/08/07.
//
//  中抜き文字を表現する為のUILabelを継承したクラス
//

#import "UIOutlineLabel.h"

@implementation UIOutlineLabel

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        // デフォルト値
        _outlineColor = [UIColor whiteColor];
        _outlineSize = 2;
    }
    return self;
}

- (void)drawTextInRect:(CGRect)rect
{
    CGContextRef cr = UIGraphicsGetCurrentContext();
    UIColor *textColor = self.textColor;
    
    CGContextSetLineWidth(cr, _outlineSize);
    CGContextSetLineJoin(cr, kCGLineJoinRound);
    CGContextSetTextDrawingMode(cr, kCGTextStroke);
    self.textColor = _outlineColor;
    [super drawTextInRect:rect];
    
    CGContextSetTextDrawingMode(cr, kCGTextFill);
    self.textColor = textColor;
    [super drawTextInRect:rect];
}

@end
