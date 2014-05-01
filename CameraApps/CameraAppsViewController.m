//
//  CameraAppsViewController.m
//  CameraApps
//
//  Created by Yuki ANAI on 5/1/14.
//  Copyright (c) 2014 Yuki ANAI. All rights reserved.
//
#import "CameraAppsViewController.h"

// @interface CameraAppsViewController ()
// @end

@implementation CameraAppsViewController
@synthesize adjustingExposure, indicatorLayer;

#define INDICATOR_RECT_SIZE 50.0

#define CAPTURE_TYPE_CAMERA 0
#define CAPTURE_TYPE_VIDEO  1

// 起動画面を長くする場合ここであれこれする
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //[NSThread sleepForTimeInterval:1.0]; // ここでスレッドを止める
    //sleep(1);
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.captureType = CAPTURE_TYPE_CAMERA; // 初期はカメラでキャプチャ
    self.statusLabel.hidden = YES; // カメラなので時間ラベルは非表示
    
    // シャッターボタンを設定
    UIImage *image;
    image = [UIImage imageNamed:@"ShutterButtonStart"];
    self.recStartImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    image = [UIImage imageNamed:@"ShutterButtonStop"];
    self.recStopImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.recBtn setImage:self.recStartImage
                 forState:UIControlStateNormal];
    [self.recBtn setTintColor:[UIColor colorWithRed:245./255.
                                              green:51./255.
                                               blue:51./255.
                                              alpha:1.0]];
    
    self.captureManager = CameraManager.new;         // カメラクラスを初期化
    self.captureManager.delegate = self;
    [self.captureManager setPreview:_previewView];   // プレビューレイヤを設定
    
    // フォーカス位置を探す
    self.indicatorLayer = [CALayer layer];
    self.indicatorLayer.borderColor = [[UIColor whiteColor] CGColor];
    self.indicatorLayer.borderWidth = 1.0;
    self.indicatorLayer.frame = CGRectMake(self.view.bounds.size.width/2.0 - INDICATOR_RECT_SIZE/2.0,
                                           self.view.bounds.size.height/2.0 - INDICATOR_RECT_SIZE/2.0,
                                           INDICATOR_RECT_SIZE,
                                           INDICATOR_RECT_SIZE);
    self.indicatorLayer.hidden = NO;
    [self.view.layer addSublayer:self.indicatorLayer];
    
    // ジェスチャ監視
    UIGestureRecognizer* gr = [[UITapGestureRecognizer alloc]
                               initWithTarget:self action:@selector(didTapGesture:)];
    [self.view addGestureRecognizer:gr];
}

// 回転禁止
- (BOOL)shouldAutorotate {
	return NO;
}

#pragma -
#pragma mark - IBAction Event Handlers

// カメラ / 動画きりかえ
- (IBAction)segment:(id)sender {
    UISegmentedControl *segmentedControl = (UISegmentedControl*) sender;
    switch (segmentedControl.selectedSegmentIndex) {
        case 0: {
            NSLog(@"Change Capture Type: Camera");
            self.captureType = CAPTURE_TYPE_CAMERA;
            self.statusLabel.hidden = YES;
            break;
        }
        case 1: {
            NSLog(@"Change Capture Type: Video");
            self.captureType = CAPTURE_TYPE_VIDEO;
            self.statusLabel.hidden = NO;
            break;
        }
        default: {
            break;
        }
    }
}

// 撮影
-(IBAction)shutter:(id)sender {
    // カメラ
    if (self.captureType == CAPTURE_TYPE_CAMERA) {
        [_captureManager takePhoto:^(UIImage *image, NSError *error) {
            // 静止画保存ここでやってる
            _captureview.image = image;
            [self saveCaptureFile:image];
        }];
        //UIImage *prevImage = [_captureManager takeCapture];
        //_captureview.image = prevImage;
    }
    // 動画
    else if (self.captureType == CAPTURE_TYPE_VIDEO) {
        // 撮影開始
        if (!self.captureManager.isRecording) {
            startTime = [[NSDate date] timeIntervalSince1970];
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                          target:self
                                                        selector:@selector(timerHandler:)
                                                        userInfo:nil
                                                         repeats:YES];
            
            [self.captureManager startRecording];
            [self.recBtn setImage:self.recStopImage
                         forState:UIControlStateNormal];
        }
        // 撮影終了
        else {
            isNeededToSave = YES;
            
            [self.timer invalidate];
            self.timer = nil;
            self.statusLabel.text = [NSString stringWithFormat:@"%.2f", 0.0];
            
            [self.captureManager stopRecording];
            [self.recBtn setImage:self.recStartImage
                         forState:UIControlStateNormal];
        }
    }
}

// 前後カメラ切り替え
-(IBAction)flip:(id)sender {
    [self.captureManager flipCamera];
}

// ライト切り替え
-(IBAction)light:(id)sender {
    [self.captureManager lightToggle];
}

// アルバム表示
-(IBAction)album:(id)sender {
    NSLog(@"ksdc");
}

#pragma -
#pragma mark - フォーカス位置指定など

- (void)setPoint:(CGPoint)p {
    CGSize viewSize = self.view.bounds.size;
    CGPoint pointOfInterest = CGPointMake(p.y / viewSize.height,
                                          1.0 - p.x / viewSize.width);
    
    AVCaptureDevice* videoCaptureDevice = _captureManager.backCameraDevice;
    NSError* error = nil;
    if ([videoCaptureDevice lockForConfiguration:&error]) {
        // フォーカスの場合は、この値を focusPointOfInterest へ渡し、focusMode を設定すれば良い
        if ([videoCaptureDevice isFocusPointOfInterestSupported] &&
            [videoCaptureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            videoCaptureDevice.focusPointOfInterest = pointOfInterest;
            videoCaptureDevice.focusMode = AVCaptureFocusModeAutoFocus;
        }
        
        // 露出の方は、exposurePointOfInterest 渡すだけでは駄目で、もう少し手間が必要
        if ([videoCaptureDevice isExposurePointOfInterestSupported] &&
            [videoCaptureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]){
            self.adjustingExposure = YES;
            videoCaptureDevice.exposurePointOfInterest = pointOfInterest;
            videoCaptureDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        }
        
        [videoCaptureDevice unlockForConfiguration];
    }
    else {
        NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, error);
    }
}

// 監視を設定しておき値が変化したら処理をする
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object change:(NSDictionary *)change
                       context:(void *)context {
    if (!self.adjustingExposure) {
        return;
    }
    
	if ([keyPath isEqual:@"adjustingExposure"]) {
		if ([[change objectForKey:NSKeyValueChangeNewKey] boolValue] == NO) {
            self.adjustingExposure = NO;
            AVCaptureDevice* videoCaptureDevice = _captureManager.backCameraDevice;
			NSError *error = nil;
			if ([videoCaptureDevice lockForConfiguration:&error]) {
                NSLog(@"%s|%@", __PRETTY_FUNCTION__, @"locked!");
				[videoCaptureDevice setExposureMode:AVCaptureExposureModeLocked];
				[videoCaptureDevice unlockForConfiguration];
			}
		}
	}
}

// タップを検知
- (void)didTapGesture:(UITapGestureRecognizer*)tgr {
    CGPoint p = [tgr locationInView:tgr.view];
    //NSLog(@"*** x:%f y:%f", p.x, p.y);
    
    // プレビュー画面の範囲内の場合のみ移動する処理をする
    if (p.x > 320 || p.y < 60 || p.y > 410) {
        return;
    }
    
    // フォーカスポイント移動
    self.indicatorLayer.frame = CGRectMake(p.x - INDICATOR_RECT_SIZE/2.0,
                                           p.y - INDICATOR_RECT_SIZE/2.0,
                                           INDICATOR_RECT_SIZE,
                                           INDICATOR_RECT_SIZE);
    [self setPoint:p];
}

#pragma -
#pragma mark - Timer Handler

// 録画時間を表示
- (void)timerHandler:(NSTimer *)timer {
    NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
    int recorded = current - startTime;
    int s = recorded % 60;
    int m = (recorded - s) / 60 % 60;
    int h = (recorded - s - m * 60) / 3600 % 3600;
    self.statusLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", h, m, s];
}

#pragma -
#pragma mark - Save function

// 静止画を保存する
- (void)saveCaptureFile:(UIImage*)captureImage {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeImageToSavedPhotosAlbum:captureImage.CGImage
                              orientation:(ALAssetOrientation)captureImage.imageOrientation // 明示的に
                          completionBlock:^(NSURL *assetURL, NSError *error) {
                              NSLog(@"saved");
                          }];
}

// 動画を保存する
- (void)saveRecordedFile:(NSURL *)recordedFile {
    //    [SVProgressHUD showWithStatus:@"Saving..."
    //                         maskType:SVProgressHUDMaskTypeGradient];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
        [assetLibrary writeVideoAtPathToSavedPhotosAlbum:recordedFile
                                         completionBlock:
         ^(NSURL *assetURL, NSError *error) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 //[SVProgressHUD dismiss];
                 
                 NSString *title;
                 NSString *message;
                 
                 if (error != nil) {
                     title = @"Failed to save video";
                     message = [error localizedDescription];
                 }
                 else {
                     title = @"Saved!";
                     message = nil;
                 }
                 
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                                 message:message
                                                                delegate:nil
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil];
                 [alert show];
             });
         }];
    });
}

#pragma -
#pragma mark - CameraManagerDelegate

- (void)didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL error:(NSError *)error {
    NSLog(@"didFinishRecordingToOutputFileAtURL");
    if (error) {
        NSLog(@"error:%@", error);
        return;
    }
    
    if (!isNeededToSave) {
        return;
    }
    
    [self saveRecordedFile:outputFileURL];
}

// リアルタイムにエフェクトかける場合に利用
//-(void)videoFrameUpdate:(CGImageRef)cgImage from:(CameraManager*)captureManager {
//UIImage* imageRotate = [CameraManager rotateImage:[UIImage imageWithCGImage:cgImage] angle:270];
//   if(captureManager.isUsingFrontCamera)
//       imageRotate = [self mirrorImage:imageRotate];
//_previewView.image = imageRotate;
//}

@end
