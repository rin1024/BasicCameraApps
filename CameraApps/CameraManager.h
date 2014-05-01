//
//  CameraManager.h
//  CameraApps
//
//  Created by Yuki ANAI on 5/1/14.
//  Copyright (c) 2014 Yuki ANAI. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CMBufferQueue.h>

////////////////////////////////////////////////
// カメラマネージャクラス
@class CameraManager;

// カメラマネージャデリゲート
@protocol CameraManagerDelegate <NSObject>
-(void)didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL error:(NSError *)error;
//@optional
//-(void)videoFrameUpdate:(CGImageRef)cgImage from:(CameraManager*)manager;
@end

//////////////////////////////////////////////////
@interface CameraManager : NSObject <AVCaptureFileOutputRecordingDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate> {
    CMTime                          defaultVideoMaxFrameDuration;
    AVCaptureSession*               captureSession;
    AVCaptureDeviceInput*           videoInput;             //  現在のビデオ入力デバイス
    AVCaptureStillImageOutput*      imageOutput;            //  静止画出力デバイス
    AVCaptureAudioDataOutput*       audioOutput;            //  オーディオ出力デバイス
    AVCaptureVideoDataOutput*       videoOutput;            //  ビデオ出力デバイス
    dispatch_queue_t                videoOutputQueue;       //  ビデオ出力用スレッド
    dispatch_queue_t                audioOutputQueue;       //  オーディオ出力用スレッド
}

@property(nonatomic, assign) id <CameraManagerDelegate> delegate;
@property (nonatomic, readonly) BOOL isRecording;

@property AVCaptureVideoPreviewLayer* previewLayer;         // previewLayer.hidden=YES/NOで切り替え
@property AVCaptureDevice*            backCameraDevice;     // バックカメラデバイス
@property AVCaptureDevice*            frontCameraDevice;    // フロントカメラデバイス
@property UIImage*                    videoImage;           // 動画まわりキャプチャした生ビデオイメージ
@property UIDeviceOrientation         videoOrientaion;      // 動画まわりキャプチャイメージの向き

@property AVCaptureMovieFileOutput*   fileOutput;           // 保存先？
@property AVCaptureDeviceFormat*      defaultFormat;        // 動画のフォーマット?

-(id)init;                                                      // 普通に初期化: 640x480
-(id)initWithPreset:(NSString*)preset;                          // 解像度指定して初期化
-(void)setPreview:(UIView*)view;                                // プレビューを表示するビューを設定する
-(void)setupAVCapture:(NSString*)preset;
-(BOOL)setupImageCapture;
-(BOOL)setupVideoCapture;
-(BOOL)setupAudioCapture;

-(void)useFrontCamera:(BOOL)yesno;                              // フロントカメラを有効にする
-(void)flipCamera;                                              // フロントカメラ・バックカメラを切り替える
-(BOOL)isUsingFrontCamera;                                      // フロントカメラを使っているか(ミラー表示中)

-(void)light:(BOOL)yesno;                                       // ライト ON/OFF
-(void)lightToggle;                                             // ライト ON/OFF切り替え
-(BOOL)isLightOn;                                               // 現在ライトがついているか

-(void)autoFocusAtPoint:(CGPoint)point;                         // フォーカス制御
-(void)continuousFocusAtPoint:(CGPoint)point;                   // フォーカス制御

typedef void(^takePhotoBlock)(UIImage *image, NSError *error);  // カメラ撮影(シャッター音あり)
-(void)takePhoto:(takePhotoBlock) block;                        // カメラ撮影(シャッター音あり)
-(void)startRecording;                                          // 録画開始
-(void)stopRecording;                                           // 録画停止
-(UIImage*)takeCapture;                                         // カメラ撮影(シャッター音なし)

-(NSUInteger) cameraCount;
-(NSUInteger) micCount;
-(AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position;
-(AVCaptureDevice *) frontFacingCamera;
-(AVCaptureDevice *) backFacingCamera;
-(AVCaptureDevice *) audioDevice;

+(CGImageRef)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer; // SampleBuffer -> CGImageRef変換
+(UIImage*)rotateImage:(UIImage*)img angle:(int)angle;               // 画像回転

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection; // ビデオキャプチャ時に新しいフレームが書き込まれた際に通知を受ける
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections;
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error;

@end
