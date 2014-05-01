//
//  CameraAppsViewController.h
//  CameraApps
//
//  Created by Yuki ANAI on 5/1/14.
//  Copyright (c) 2014 Yuki ANAI. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "CameraManager.h"
//#import "SVProgressHUD.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface CameraViewController : UIViewController<CameraManagerDelegate> {
    NSTimeInterval startTime;
    BOOL isNeededToSave;
}

@property CameraManager* captureManager;  // 動画マネージャクラス
@property uint8_t captureType;               // キャプチャの方法(0:カメラ, 1:動画)

@property (nonatomic, assign) NSTimer *timer;
@property (nonatomic, strong) UIImage *recStartImage;
@property (nonatomic, strong) UIImage *recStopImage;

@property (nonatomic, strong) CALayer* indicatorLayer;  // ピント合わせる用のレイヤ
@property (nonatomic) BOOL adjustingExposure;           // 露出補正用のだっけ?

@property IBOutlet UIImageView* previewView; // 動画プレビューを配置するビュー
@property IBOutlet UIImageView* captureview; // キャプチャ後のイメージ
@property IBOutlet UILabel *statusLabel;     // 時間表示用ラベル
@property IBOutlet UIButton *recBtn;         // 撮影ボタン
@property IBOutlet UIButton *albumBtn;       //

- (void)setPoint:(CGPoint)p;

@end
