//
//  ViewController.m
//  CellsMaker
//
//  Created by ooyama on 2014/08/06.
//
//

#import "ViewController.h"

//#define CLEAR_SCORE 200  //クリアスコア
#define CLEAR_SCORE 15  //デバッグ用スコア

enum {START, PLAY, END}; //モード状態識別子
enum {EASY = 101, NOMAL, HARD, PROGRESS, RETRY, TIME, CLEAR, MODE}; //ボタン種類tagとプログレスバーのtagと最後に表示されるタイムラベルtagとクリアメッセージラベルのtag
enum {BORN, ALIVE, DIE, FREE1, FREE2}; //１クールの状態
enum {GOOD_POINT_NOMAL = 5, GOOD_POINT_HARD = 1, EXCELLENT_POINT = 10, BAD_POINT = -1}; //点数定数
enum {EXCELLENT, GOOD, BAD}; //吹き出し表示ディスパッチ用の列挙
enum {CLOSE, OPEN}; //両腕開閉アニメーション用
enum {TWITTER = 201, FACEBOOK}; //ソーシャル連携用

@interface ViewController ()
@end

@implementation ViewController
{
    int modeStatus;           //モード状態識別変数
    int mode;                 //選択モード識別変数(EASY:0、NOMAL:1、HARD:2)
    int mainFlg;              //メインの状態フラグ(BORN:0 → ALIVE:1 → DIE:2 → 0)　※途中でフリー状態(FREE1:3, FREE2:4)も存在する
    int summary;              //長押し終了時の秒数　３桁表示（例：１秒→100）
    int score;                //スコア
    UILabel *scoreLabel;      //右上のスコアラベル
    UILabel *timeLabel;       //右上のタイムラベル
    NSTimer *heartBeatTimer;  //心臓タイマー
    NSTimer *longPressTimer;  //長押しタイマー
    NSTimer *elapsedTimer;    //経過時間タイマー
    NSDate *startTime;        //経過時間タイマーの基点
    NSDate *pressTime;        //長押しタイマーの基点
    NSMutableArray *messages; //吹き出し表示用部品格納配列　配列の中に３要素を持つ配列の２次元配列になる予定
    SystemSoundID soundID[3]; //効果音 0:エクセレント 1:グッド 2:バッド
    BOOL cellBornColorFlg;    //細胞が生まれてから中央に来た後に一回だけ色変化メソッドを呼ぶためのフラグ
    NADView *nadView;         //Nend用のView
    UIButton *twitterButton;  //Twitterボタン
    UIButton *facebookButton; //Facebookボタン
}

#pragma mark - 共通部品生成
//ラベル生成 UILabel継承した自作クラスで作成
- (UILabel *)makeLabel:(NSString *)text rect:(CGRect)rect
{
    UIOutlineLabel *label = [[UIOutlineLabel alloc] initWithFrame:rect];
    label.text = text;
    label.textColor = [UIColor yellowColor];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:16];
    
    //中抜き文字用の設定
    label.outlineColor = [UIColor magentaColor]; // 縁取りの色
    label.outlineSize = 1; // 縁取りの太さ
    
    return label;
}

//ボタン生成
- (void)makeButton:(NSString *)text rect:(CGRect)rect tag:(int)tag
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:text forState:UIControlStateNormal];
    button.frame = rect;
    button.tag = tag;
    [button addTarget:self action:@selector(pressButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

//吹き出しレイヤー生成
- (void)makeMessage:(NSArray *)imageNames texts:(NSArray *)imageTexts textColors:(NSArray *)textColors
{
    //吹き出し表示用部品格納配列の準備
    messages = [NSMutableArray new];
    
    //各３種類の吹き出しレイヤーの生成
    for (int i = 0; i < imageNames.count; i++) {
        //吹き出し要素(画像、テキスト、時間ラベル)格納用Arrayの準備
        NSMutableArray *array = [NSMutableArray new];
        
        //画像の準備
        UIImage *image = [UIImage imageNamed:imageNames[i]];
        
        //吹き出し画像レイヤー作成
        CALayer *imageLayer = [CALayer layer];
        imageLayer.contents = (id)image.CGImage;
        imageLayer.frame = CGRectMake(self.view.bounds.size.width / 2 - image.size.width / 4, 220, image.size.width / 2, image.size.height / 2);
        imageLayer.opacity = 0.0; //透明のはず
        [array addObject:imageLayer];
        
        //メッセージ用テキストレイヤー作成
        CATextLayer *textLayer = [CATextLayer layer];
        textLayer.string = imageTexts[i];
        textLayer.fontSize = 16;
        textLayer.alignmentMode = kCAAlignmentCenter; // 中央寄せ
        textLayer.foregroundColor = [UIColor blackColor].CGColor;
        textLayer.frame = CGRectMake(10, 40, image.size.width / 2 - 20, image.size.height / 2 - 30); // 位置取りしやすいように画像と同じサイズにする
        [array addObject:textLayer];
        
        //経過タイム用テキストレイヤー作成
        CATextLayer *timeTextLayer = [CATextLayer layer];
        timeTextLayer.string = @"";
        timeTextLayer.fontSize = 16;
        timeTextLayer.alignmentMode = kCAAlignmentCenter; // 中央寄せ
        UIColor *textColor = (UIColor *)textColors[i];
        timeTextLayer.foregroundColor = textColor.CGColor; //文字色
        timeTextLayer.frame = CGRectMake(10, 70, image.size.width / 2 - 20, image.size.height / 2 - 30); // 位置取りしやすいように画像と同じサイズにする
        [array addObject:timeTextLayer];
        
        //レイヤー追加
        [imageLayer addSublayer:textLayer];
        [imageLayer addSublayer:timeTextLayer];
        [self.view.layer addSublayer:imageLayer];
        
        //大元のArrayに追加
        [messages addObject:array];
    }
}

#pragma mark - 不要部品削除
//不要部品の削除(UIView限定　※CALayerは各メソッドで削除)
- (void)removeView:(NSArray *)views
{
    //UIViewをself.viewから削除
    for (UIView *view in views) {
        [view removeFromSuperview];
    }
}

#pragma mark - レイヤー特定
//子レイヤー名を特定するメソッド
- (CALayer *)findLayer:(NSString *)name
{
    CALayer *returnLayer = nil;
    for (CALayer *layer in self.view.layer.sublayers) {
        if([layer.name isEqualToString:name]) {
            returnLayer = layer;
            break;
        }
    }
    return returnLayer; //無い場合はnilを返す
}

#pragma mark - 初期化
//初期化
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //背景画像(研究室っぽい器具や棚、机など)の生成とself.viewへの設置
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
    
    ////吹き出し画像 + 吹き出しテキストラベル + 経過秒数表示ラベルの生成メソッドコール
    NSArray *imageNames = @[@"excellent.png", @"good.png", @"bad.png"]; //吹き出し画像ファイル名Array
    NSArray *imageTexts = @[@"EXCELLENT!!!", @"GOOD!", @"BAD・・・"];    //吹き出しに表示するテキストArray
    NSArray *imageColors = @[[UIColor purpleColor], [UIColor blueColor], [UIColor redColor]];    //吹き出しに表示するテキスト色Array
    [self makeMessage:imageNames texts:imageTexts textColors:imageColors];
    
    //効果音の準備
    NSArray *soundNames = @[@"excellent", @"good", @"bad"];
    for (int i = 0; i < soundNames.count; i++) {
        NSURL *url=[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:soundNames[i] ofType:@"mp3"]];
        AudioServicesCreateSystemSoundID(CFBridgingRetain(url), &soundID[i]);
    }
    
    //総合経過タイムラベルと累計スコアラベルの生成と配置
    timeLabel =  [self makeLabel:@"" rect:CGRectMake(self.view.bounds.size.width - 133, 30, 130, 30)];
    scoreLabel = [self makeLabel:@"" rect:CGRectMake(self.view.bounds.size.width - 150, 55, 149, 30)];
    [self.view addSubview:timeLabel];
    [self.view addSubview:scoreLabel];
    
    //選択モード識別変数を念のため「EASY」(101)で初期化しとこう
    mode = EASY;
    
    //メインの状態フラグを「START」(0 - シャーレを左外から中央に持って来る状態)で初期化しとこう
    mainFlg = BORN;
    
    //起動直後の状態はモード「START」モードでモード初期化メソッドコール
    modeStatus = START;
    [self modeInit];
    
    //twitter連携ボタン配置
    twitterButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width / 2 - 130, 310, 40, 40)];
    [twitterButton setBackgroundImage:[UIImage imageNamed:@"twitter.png"] forState:UIControlStateNormal];
    [twitterButton addTarget:self action:@selector(socialButton:) forControlEvents:UIControlEventTouchUpInside];
    [twitterButton setTag:TWITTER];
    [self.view addSubview:twitterButton];
    
    //facebook連携ボタン配置
    facebookButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width / 2 + 90, 310, 40, 40)];
    [facebookButton setBackgroundImage:[UIImage imageNamed:@"facebook.png"] forState:UIControlStateNormal];
    [facebookButton addTarget:self action:@selector(socialButton:) forControlEvents:UIControlEventTouchUpInside];
    [facebookButton setTag:FACEBOOK];
    [self.view addSubview:facebookButton];
    
    //ソーシャルボタン非表示
    twitterButton.hidden = YES;
    facebookButton.hidden = YES;
    
    //NEND広告の実装
    nadView = [[NADView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 50, 320, 50)];
    
    [nadView setIsOutputLog:NO];
    [nadView setNendID:@"4a71a479bc3913c3275354638dfb0766d86b13be" spotID:@"224710"]; //仮契約
    nadView.delegate = self;
    [nadView load];
    
    [self.view addSubview:nadView];
    
    //NEND広告非表示
    nadView.hidden = YES;
    
}

//モード別初期化
- (void)modeInit
{
    switch (modeStatus) {
        case START: //スタート画面
            
            //累計スコアと総合経過タイムのリセット
            timeLabel.text  = @"TIME : 00:00:00";
            scoreLabel.text = @"SCORE : 000 / 200";
            score = 0;
            
            //「イージーモード」、「ノーマルモード」、「ハードモード」の各ボタン生成
            [self makeButton:@"EASY    MODE" rect:CGRectMake(self.view.bounds.size.width / 2 - 100, 220, 200, 40) tag:EASY];
            [self makeButton:@"NOMAL MODE" rect:CGRectMake(self.view.bounds.size.width / 2 - 100, 260, 200, 40) tag:NOMAL];
            [self makeButton:@"HARD    MODE" rect:CGRectMake(self.view.bounds.size.width / 2 - 100, 300, 200, 40) tag:HARD];

            
            //ゲームオーバー画面のタイムラベルとリスタートボタンとクリアメッセージラベルの削除　※どっちか一つしか無いって状態はあり得ない　初回起動時は何も無いはずだからこのifが必要
            if ([self.view viewWithTag:RETRY] /* && [self.view viewWithTag:TIME] */) {
                NSMutableArray *array = [NSMutableArray array];
                [array addObject:[self.view viewWithTag:RETRY]];
                [array addObject:[self.view viewWithTag:TIME]];
                [array addObject:[self.view viewWithTag:CLEAR]];
                [array addObject:[self.view viewWithTag:MODE]];
                [self removeView:array];
                
                //ソーシャルボタン非表示
                twitterButton.hidden = YES;
                facebookButton.hidden = YES;
                
                //NEND広告非表示
                nadView.hidden = YES;
            }

            break;
            
        case PLAY: //ゲームプレイ画面
        {   //モード選択ボタン(３種類)を削除 ※case文の中で変数宣言するためにはブロック({})で囲わないとエラーになるんだって　へーへーへー
            NSMutableArray *array = [NSMutableArray array];
            [array addObject:[self.view viewWithTag:EASY]];
            [array addObject:[self.view viewWithTag:NOMAL]];
            [array addObject:[self.view viewWithTag:HARD]];
            [self removeView:array];
        }
        {   //小保方さんの「土台」を生成　本体画像などはOboLayerクラス側に記述
            OboLayer *obokata = [OboLayer new];
            obokata.frame = CGRectMake(self.view.bounds.size.width / 2 - 100, 340, 200, 400);
            obokata.name = @"OBO";
            [obokata setBuhin];
            [self.view.layer addSublayer:obokata];
        }
            //イージーモードの場合はプレグレスバー生成
            if (mode == EASY) {
                UIProgressView *progressBar = [[UIProgressView alloc]  initWithProgressViewStyle:UIProgressViewStyleDefault];
                progressBar.frame = CGRectMake(self.view.bounds.size.width / 2 - 120, 200, 240, 20);
                progressBar.tag = PROGRESS;
                progressBar.progressTintColor = [UIColor redColor];
                progressBar.trackTintColor = [UIColor blackColor];
                progressBar.progress = 0.0;
                progressBar.transform = CGAffineTransformMakeScale(0.7, 8.0);//縦に8.0倍、横に0.7倍に引き伸ばす(iOS7用)
                
                //ios6とios7でサイズ感が変わるのでディスパッチ　めんどくせえ・・・
                /* ios6対応はもういいでしょ？　2015/03/02下記ディスパッチはコメントアウト
                if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
                    progressBar.transform = CGAffineTransformMakeScale(0.7, 8.0);//縦に8.0倍、横に0.7倍に引き伸ばす(iOS7用)
                }else{
                    progressBar.transform = CGAffineTransformMakeScale(0.7, 1.5);//縦に1.5倍、横に0.7倍に引き伸ばす(iOS6用)
                }
                */
                
                [self.view addSubview:progressBar];
            }
            
            //経過時間用のタイマー
            startTime = [NSDate date];
            elapsedTimer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(displayElapsed) userInfo:nil repeats:YES];
            
            //心臓タイマー
            heartBeatTimer = [NSTimer scheduledTimerWithTimeInterval:.05 target:self selector:@selector(mainBatch) userInfo:nil repeats:YES];
            
            //細胞が生まれてから中央に来た後に一回だけ色変化メソッドを呼ぶためのフラグの初期化
            cellBornColorFlg = NO;
            
            break;
            
        case END: //ゲームオーバー画面
            //ゲームプレイ画面の小保方さんの削除
            [[self findLayer:@"OBO"] removeFromSuperlayer];
            
            //イージーモードならプログレスバーも削除
            if (mode == EASY) {
                NSArray *array = @[[self.view viewWithTag:PROGRESS]];
                [self removeView:array];
            }
            
            //経過時間と心臓タイマーを停止
            [elapsedTimer invalidate];
            [heartBeatTimer invalidate];
            elapsedTimer = nil;
            heartBeatTimer = nil;
            
        {   //クリアタイムラベル、クリアモードラベル、リスタートボタンの生成
            UILabel *clearMessage =  [self makeLabel:@"" rect:CGRectMake(self.view.bounds.size.width / 2 - 150, 210, 300, 50)];
            clearMessage.tag = CLEAR;
            clearMessage.text = @"GAME CLEARED!!";
            clearMessage.textAlignment = NSTextAlignmentCenter;
            clearMessage.font = [UIFont systemFontOfSize:36];
            [self.view addSubview:clearMessage];
            
            //クリア画面に選択モードも表示すべきだった
            NSArray *clearMode = @[@"EASY", @"NOMAL", @"HARD"];
            UILabel *modeLabel =  [self makeLabel:@"" rect:CGRectMake(self.view.bounds.size.width / 2 - 100, 250, 200, 40)];
            modeLabel.tag = MODE;
            modeLabel.text = [@"MODE : " stringByAppendingString:clearMode[mode - 101]];
            modeLabel.textAlignment = NSTextAlignmentCenter;
            [self.view addSubview:modeLabel];
            
            
            UILabel *clearLabel =  [self makeLabel:@"" rect:CGRectMake(self.view.bounds.size.width / 2 - 100, 270, 200, 40)];
            clearLabel.tag = TIME;
            clearLabel.text = [@"CLEAR " stringByAppendingString:timeLabel.text];
            clearLabel.textAlignment = NSTextAlignmentCenter;
            [self.view addSubview:clearLabel];
            
            //RETRYボタンの配置
            [self makeButton:@"RETRY" rect:CGRectMake(self.view.bounds.size.width / 2 - 100, 310, 200, 40) tag:RETRY];
        }
            //ソーシャルボタン表示
            twitterButton.hidden = NO;
            facebookButton.hidden = NO;
            
            //NEND広告表示
            nadView.hidden = NO;
            
            break;
            
        default://例外処理必要？？
            break;
    }
}

#pragma mark - ボタン押下時の挙動
//ボタンターゲット
- (void)pressButton:(UIButton *)sendar
{
    if (sendar.tag == RETRY) {
        modeStatus = START; //「START」モードに変更
    } else {
        mode = (int)sendar.tag; //イージーとそれ以外(ノーマルかハード)のどっちが選択されたかをmode変数に格納しといて後でプログレスバー生成有無に使う
        modeStatus = PLAY; //「PLAY」モードに変更
    }
    
    //モード初期化メソッドをコール
    [self modeInit];
}

#pragma mark - プレイ系メソッド
//経過時間表示メソッド
- (void)displayElapsed
{
    NSTimeInterval since = [[NSDate date] timeIntervalSinceDate:startTime];
    
    int minite = fmod((since / 60), 60);
    int second = fmod(since, 60);
    int milliSecond = (since - floor(since)) * 100;
    
    timeLabel.text  = [NSString stringWithFormat:@"TIME : %02d:%02d:%02d", minite, second, milliSecond];
}

//メイン処理メソッド
- (void)mainBatch
{
    switch (mainFlg) {
        case BORN: //ゲームスタート時 or 長押し終了後にシャーレが右外に出た後のタイミング状態
            //画面左外 → 画面中央へのアニメーション
            [self makeAnimation:CGRectMake(self.view.bounds.size.width / 2 - 50, 250, 100, 75)];
            
            //mainFlgをFREE1(3)へ
            mainFlg = FREE1;
            
            break;
            
        case ALIVE: //シャーレが画面中央にアニメーション完了したタイミング状態
            //中央に来た瞬間細胞の色を白に変更
            if (!cellBornColorFlg) {
                CellLayer *cell = (CellLayer *)[self findLayer:@"CELL"];
                cell.cellImage.backgroundColor = [UIColor whiteColor].CGColor;
                cellBornColorFlg = YES;
            }
            
            break;
            
        case DIE: //長押しが完了したタイミング状態
            //画面中央 → 画面右外へのアニメーション
            [self makeAnimation:CGRectMake(self.view.bounds.size.width - 50, 250, 100, 75)];
            
            //mainFlgをFREE2(4)へ
            mainFlg = FREE2;
            
            //長押し秒数を初期化
            summary = 0;
            
            //イージーモードはプログレスバー表示も０に初期化
            if (mode == EASY) {
                UIProgressView *progressBar = (UIProgressView *)[self.view viewWithTag:PROGRESS];
                [progressBar setProgress:0.0f animated:NO];
            }
            
            break;
            
        default:
            //mainFlgがFREE1とFREE2の場合はここが選択されるから処理なしでスルー
            break;
    }
}

#pragma mark - アニメーション
//アニメーション共通メソッド
- (void)makeAnimation:(CGRect)rect
{
    //x軸(横方向)のアニメーション
    CABasicAnimation *anime = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    
    //animationDidStopメソッドを呼ぶためにデリゲート設定
    anime.delegate = self;
    
    //アニメーション時間
    anime.duration = 0.4;
    
    // 終了状態 配置場所(中央、画面右端)まで移動
    anime.toValue = @0;
    
    //細胞が存在しなければ(START時点だったら)生成し、存在すれば(END時点だったら)再利用
    CellLayer *cell = (CellLayer *)[self findLayer:@"CELL"];
    
    //存在すれば再利用して中央から右へ消し、存在しなかったら細胞インスタンスを生成する
    if (cell) {
        //細胞インスタンスの取得
        cell.position = CGPointMake(cell.frame.origin.x + 185 + 100, cell.frame.origin.y + 50);
        
        // アニメーション設定　開始状態 X座標を中央から〜
        anime.fromValue = @0;
    } else {
        //細胞を生成
        cell = [CellLayer new];
        cell.frame = rect;
        cell.contents = (id)[UIImage imageNamed:@"syare.png"].CGImage;
        cell.name = @"CELL";
        [self.view.layer addSublayer:cell];
        
        // アニメーション設定　開始状態 X座標を-185(320 / 2 + 25)から〜
        anime.fromValue = @(-185 - 100);
    }
    
    // レイヤーにレイヤーアニメーションを設定
    [cell addAnimation:anime forKey:@"cellAnimeForCenter"];
}

//(delegate設定されている)アニメーション終了時(細胞が中央に来た時と、右端に捌けた時)にコールされる
//細胞生成アニメーションだったらモードをPLAYに、細胞死亡アニメーションだったらモードをSTARTへ
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (mainFlg == FREE1) {
        mainFlg = ALIVE;
        cellBornColorFlg = NO;
    } else if (mainFlg == FREE2) {
        //画面の右外に消えたら当該の細胞インスタンスは削除してフラグをBORNに切り替え
        [[self findLayer:@"CELL"] removeFromSuperlayer];
        mainFlg = BORN;
        
        //スコアが２００点になったらゲーム終了
        if (score >= CLEAR_SCORE) {
            scoreLabel.text = @"SCORE : 200 / 200"; //200点超えたら200点に戻す
            modeStatus = END;
            [self modeInit];
        }
    }
}

//吹き出し表示用メソッド
- (void)displayMessage:(int)kind
{
    CALayer *fukidashiLayer = (CALayer *)messages[kind][0];
    CATextLayer *timeText = (CATextLayer *)messages[kind][2];
    timeText.string = [NSString stringWithFormat:@"%.02fsec", (float)summary / 100];
    
    //もわーっと表示されて、もわーっと消えるアニメーション
    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.duration = 0.5f;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]; //はじめ速くて徐々にゆっくり
    animation.autoreverses = YES;
    animation.fromValue = @0.0f; //MIN opacity = Alphaみたいなもん
    animation.toValue = @1.0f; //MAX opacity = Alphaみたいなもん
    [fukidashiLayer addAnimation:animation forKey:@"blink"];
    
    //吹き出し用効果音発射
    AudioServicesPlaySystemSound(soundID[kind]);
}

#pragma mark - タッチイベント
//タッチ開始
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //タッチした位置にあったレイヤーの取得
    CALayer *layer = [self.view.layer hitTest:[[touches anyObject] locationInView:self.view]];
    
    //シャーレが中央に無く、小保方さんをタッチしてなかったら、以降の処理スルー
    if ( !([layer.name isEqualToString:@"OBOBO"] && mainFlg == ALIVE) ) return;
    
    //得点表示(＋５とか)レイヤー削除
    [(CATextLayer *)[self findLayer:@"POINT"] removeFromSuperlayer];
    
    //両腕閉じる
    [(OboLayer *)[self findLayer:@"OBO"] openCloseAnimation:CLOSE];
    
    //長押しタイマースタート
    pressTime = [NSDate date];
    longPressTimer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(longPress) userInfo:nil repeats:YES];
}

//タッチ終了
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //タッチした位置にあったレイヤーの取得
    CALayer *layer = [self.view.layer hitTest:[[touches anyObject] locationInView:self.view]];
    
    //シャーレが中央に無く、小保方さんをタッチしてなかったら、以降の処理スルー
    if ( !([layer.name isEqualToString:@"OBOBO"] && mainFlg == ALIVE) ) return;
    
    //両腕開く
    [(OboLayer *)[self findLayer:@"OBO"] openCloseAnimation:OPEN];
    
    //長押しタイマーのストップと破棄
    [longPressTimer invalidate];
    longPressTimer = nil;
    pressTime = nil;
    
    //スコアセット用の変数を用意
    int nowScore = 0;
    
    //吹き出しの表示と非表示メソッドコール ハードモードはBad:-1,Good:1, Excellent:10点
    if (summary == 100) {
        [self displayMessage:EXCELLENT];
        nowScore = EXCELLENT_POINT;
    } else if (105 >= summary && summary >= 95) {
        [self displayMessage:GOOD];
        nowScore = GOOD_POINT_NOMAL;
        if (mode == HARD) nowScore = GOOD_POINT_HARD;
    } else {
        [self displayMessage:BAD];
        if (mode == HARD && score > 0) nowScore = BAD_POINT;
    }
    
    //スコアの加算と更新
    scoreLabel.text = [NSString stringWithFormat:@"SCORE : %.3d / 200", score += nowScore];
    
    //細胞の死亡フラグを立てる
    mainFlg = DIE;
    
    //取得ポイントアニメーション 0点だったら以下の処理スルー
    if (nowScore == 0) return;
    
    CATextLayer *pointText = [CATextLayer new];
    pointText.frame = CGRectMake(220, 350, 70, 50);
    pointText.string = nowScore > 0 ? [NSString stringWithFormat:@"+%d", nowScore] : [NSString stringWithFormat:@"%d", nowScore];
    pointText.foregroundColor = nowScore > 0 ? [UIColor greenColor].CGColor : [UIColor magentaColor].CGColor;
    pointText.fontSize = 32;
    pointText.name = @"POINT";
    
    //@[数字]　の書き方で数字リテラルをNSNumber型に出来る!!!!!!!!!!!!!!!!!!!!!!!
    //もわーっと表示されて、もわーっと消えるアニメーション
    CABasicAnimation *animation1 = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation1.fromValue = @1.0f;
    animation1.toValue = @0.0f;
    
    //Y座標を指定するアニメーション
    CABasicAnimation *animation2 = [CABasicAnimation animationWithKeyPath:@"position.y"];
    animation2.fromValue = @290.0;
    animation2.toValue = @220.0;
    
    //X座標を指定するアニメーション
    CABasicAnimation *animation3 = [CABasicAnimation animationWithKeyPath:@"position.x"];
    animation3.fromValue = @280.0f;
    animation3.toValue = @280.0f;
    
    //アニメーショングループを作成
    CAAnimationGroup *group = [CAAnimationGroup animation];
    
    //アニメーショングループの設定
    group.duration = 0.7;
    group.removedOnCompletion = NO;
    group.fillMode = kCAFillModeForwards;
    
    //グループにアニメーションを追加
    group.animations = @[animation1, animation2, animation3];
    [pointText addAnimation:group forKey:@"group-animation"];
    
    [self.view.layer addSublayer:pointText];
    
}

//長押しタイマーから呼ばれる
- (void)longPress
{
    //経過秒数とミリ秒数を掛け合わせて３桁数字を作る　（例：１秒→100）
    NSTimeInterval since = [[NSDate date] timeIntervalSinceDate:pressTime];
    int second = fmod(since, 60);
    int miliSecond = (since - floor(since)) * 100;
    summary = second * 100 + miliSecond;
    
    //細胞の色を変化させる
    CellLayer *cell = (CellLayer *)[self findLayer:@"CELL"];
    cell.cellImage.backgroundColor = [UIColor colorWithRed:(80 - summary) / 100.0 green:1.0 blue:(80 - summary) / 100.0 alpha:1.0].CGColor;
    
    //イージーモードならプログレスバー表示
    if (mode == EASY) {
        UIProgressView *progressBar = (UIProgressView *)[self.view viewWithTag:PROGRESS];
        
        //バーの進捗をなるべく滑らかにするために小数点１桁で切り捨て
        float floatVal = [[NSString stringWithFormat:@"%.1f", summary / 90.0] floatValue]; //なぜか80.0だと実機で見たらずれる
        
        [progressBar setProgress:floatVal animated:YES];
    }
}

#pragma mark - Twitter連携
- (void)socialButton:(UIButton *)button
{
    //画面キャプチャ
    UIImage *srcCaptureImage = [ViewController getScreenShotImage] ;
    CGRect trimArea = CGRectMake(0, 0, self.view.bounds.size.width, 300);
    
    //トリミング
    UIGraphicsBeginImageContext(trimArea.size);
    [srcCaptureImage drawAtPoint:trimArea.origin];
    UIImage *captureImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //Twitterの場合
    if (button.tag == TWITTER) {
        //アカウント設定チェック
        if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
            [[[UIAlertView alloc] initWithTitle:@""
                                        message:@"Please set your Twitter account in your iPhone settings"
                                       delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
            return;
        }
        
        SLComposeViewController *twitter = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [twitter addImage:captureImage];
        [self presentViewController:twitter animated:YES completion:nil];
        
    } else if (button.tag == FACEBOOK) {
        //アカウント設定チェック
        if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
            [[[UIAlertView alloc] initWithTitle:@""
                                        message:@"Please set your Facebook account in your iPhone settings"
                                       delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
            return;
        }
        
        SLComposeViewController *facebook = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [facebook addImage:captureImage];
        [self presentViewController:facebook animated:YES completion:nil];
    }
    
}

//画面キャプチャ取得用のクラスメソッド
+ (UIImage *)getScreenShotImage {
    
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    
    UIGraphicsBeginImageContextWithOptions(window.bounds.size, NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Windowの現在の表示内容を１つずつ描画。
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
        [window.layer renderInContext:context];
    }
    
    UIImage *capturedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return capturedImage;
}


#pragma mark - メモリワーニング
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"Memory Warning");//メモリやばいよ
}

@end
