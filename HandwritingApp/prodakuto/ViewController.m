
#import "ViewController.h"
//#import "msgpack-objectivec/MessagePack.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *canvas;
- (IBAction)Trash:(id)sender;
- (IBAction)RecognizePhoto:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *Recognize_btn;
@property (strong, nonatomic) IBOutlet UIButton *Trash_btn;
@property (strong, nonatomic) IBOutlet UILabel *label;

@end

int mojinum=0;
NSMutableArray *MojiData;
NSDate *startDate;
NSDate *endDate;

@implementation ViewController

int top=0,under=0,right=0,left=0;

- (void)viewDidLoad {
    [super viewDidLoad];
    _canvas.image=[UIImage imageNamed:@"white.png"];
    CALayer *layer = [_canvas layer];
    [layer setMasksToBounds:YES];
    [layer setBorderWidth: 3.f];
    [layer setBorderColor:[[UIColor blackColor] CGColor]];
    [self.view insertSubview:_canvas atIndex:0];
    //jsonをパース
    MojiData = [self ParseJson];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    // タッチ開始座標をインスタンス変数touchPointに保持
    UITouch *touch = [touches anyObject];
    touchPoint = [touch locationInView:_canvas];
    
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    





}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
    // 現在のタッチ座標をローカル変数currentPointに保持
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:_canvas];
    
    // 描画領域をcanvasの大きさで生成
    UIGraphicsBeginImageContext(_canvas.frame.size);
    
    // canvasにセットされている画像（UIImage）を描画
    [_canvas.image drawInRect:
     CGRectMake(0, 0, _canvas.frame.size.width, _canvas.frame.size.height)];
    
    // 線の角を丸くする
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    
    // 線の太さを指定
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);
    
    // 線の色を指定（RGB）
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.0, 0.0, 0.0, 1.0);
    
    // 線の描画開始座標をセット
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), touchPoint.x, touchPoint.y);
    
    // 線の描画終了座標をセット
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
    
    // 描画の開始～終了座標まで線を引く
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    
    // 描画領域を画像（UIImage）としてcanvasにセット
    _canvas.image = UIGraphicsGetImageFromCurrentImageContext();
    
    // 描画領域のクリア
    UIGraphicsEndImageContext();
    
    // 現在のタッチ座標を次の開始座標にセット
    touchPoint = currentPoint;
}

- (IBAction)Trash:(id)sender {
    _canvas.image = nil;
    _canvas.image=[UIImage imageNamed:@"white.png"];
}

- (IBAction)RecognizePhoto:(id)sender {
    
    _Recognize_btn.enabled=NO;
    _Trash_btn.enabled=NO;
    [SVProgressHUD showInfoWithStatus:@"Recognizing..." maskType:SVProgressHUDMaskTypeGradient];
    [self performSelector:@selector(Recognize) withObject:nil afterDelay:0.1];
    
}

- (void)Recognize{
    
    //切り抜き画像を作成
    UIImage *trimmed;
    trimmed=[self CutImage];
    
    //画像データ化
    NSMutableArray *TegakiData = [self MakeData:trimmed];
    
    //照合
    startDate = [NSDate date];
    [self findMoji:TegakiData];
    endDate = [NSDate date];
    NSTimeInterval interval = [endDate timeIntervalSinceDate:startDate];
    NSLog(@"処理開始時間 = %@",[self getDateString:startDate]);
    NSLog(@"処理終了時間 = %@",[self getDateString:endDate]);
    NSLog(@"処理時間 = %.3f秒",interval);
    
    //画像保存
    NSData *data = UIImagePNGRepresentation(trimmed);
    NSString *filePath = [NSString stringWithFormat:@"%@/moji.png" , [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]];
    
    NSLog(@"%@", filePath);
    if ([data writeToFile:filePath atomically:YES]) {
        NSLog(@"OK");
        [SVProgressHUD showSuccessWithStatus:@"Finish!"];
    } else {
        NSLog(@"Error");
        [SVProgressHUD showErrorWithStatus:@"Failed with Error"];
    }
    
    _Recognize_btn.enabled=YES;
    _Trash_btn.enabled=YES;


}

- (NSString*)getDateString:(NSDate*)date
{
    // 日付フォーマットオブジェクトの生成
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    // フォーマットを指定の日付フォーマットに設定
    [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss.SSS"];
    // 日付の文字列を生成
    NSString *dateString = [dateFormatter stringFromDate:date];
    
    return dateString;
}

- (UIImage*)CutImage{
    
    UInt8* pixelPtr[256][256]={0};
    // CGImageを取得する
    CGImageRef imageRef = _canvas.image.CGImage;
    // データプロバイダを取得する
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    // ビットマップデータを取得する
    UInt8* buffer = (UInt8*)CFDataGetBytePtr(CGDataProviderCopyData(dataProvider));
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    
    // 画像全体を１ピクセルずつ走査する
    
    for (int i=0; i<256; i++) {
        for (int j=0; j<256; j++){
            pixelPtr[i][j] = buffer + (int)(j) * bytesPerRow + (int)(i) * 4;
        }
    }
    
    for (int x=1; x<_canvas.image.size.width-1; x++) {
        for (int y=1; y<_canvas.image.size.height-1; y++) {
            
            // 色情報を取得する
            UInt8 b = *(pixelPtr[x][y] + 0);
            if (b==0) {
                left=x;
                x=_canvas.image.size.width;
                y=_canvas.image.size.height;
            }
        }
        if ( x > _canvas.image.size.width-5 && x != _canvas.image.size.width){
            
            [SVProgressHUD showErrorWithStatus:@"Failed with Error"];
            _Recognize_btn.enabled=YES;
            _Trash_btn.enabled=YES;
            return nil;
            
        }
    }
    for (int x=254; x>1; x--) {
        for (int y=254; y>1; y--) {
            
            // 色情報を取得する
            UInt8 b = *(pixelPtr[x][y] + 0);
            if (b==0) {
                right=x;
                x=0;
                y=0;
            }
        }
    }
    for (int y=1; y<_canvas.image.size.width-1; y++) {
        for (int x=1; x<_canvas.image.size.height-1; x++) {
            
            // 色情報を取得する
            UInt8 b = *(pixelPtr[x][y] + 0);
            if (b==0) {
                top=y;
                x=_canvas.image.size.width;
                y=_canvas.image.size.height;
            }
        }
    }
    for (int y=254; y>1; y--) {
        for (int x=254; x>1; x--) {
            
            // 色情報を取得する
            UInt8 b = *(pixelPtr[x][y] + 0);
            if (b==0) {
                under=y;
                x=0;
                y=0;
            }
        }
    }
    NSLog(@"top%d:under%d:left%d:right%d",top,under,left,right);
    
    //切り抜き範囲の設定
    CGRect trimArea = CGRectMake(left, top, right-left, under-top);
    
    // 切り抜いた画像を作成する
    CGImageRef srcImageRef = [_canvas.image CGImage];
    CGImageRef trimmedImageRef = CGImageCreateWithImageInRect(srcImageRef, trimArea);
    UIImage *trimmedImage = [UIImage imageWithCGImage:trimmedImageRef];
    
    return trimmedImage;
}


-(NSMutableArray*)MakeData:(UIImage*)Image{
    
    UInt8* pixelPtr2[256][256]={0};
    // CGImageを取得する
    CGImageRef imageRef = _canvas.image.CGImage;
    // データプロバイダを取得する
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    // ビットマップデータを取得する
    UInt8* buffer = (UInt8*)CFDataGetBytePtr(CGDataProviderCopyData(dataProvider));
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    
    for (int i=0; i<256; i++) {
        
        for (int j=0; j<256; j++){
            pixelPtr2[i][j] = buffer + (int)(j) * bytesPerRow + (int)(i) * 4;
        }
    }
    
    int AmariX = (int)Image.size.width%32 , AmariY = (int)Image.size.height%32;
    int territoryX = (Image.size.width+(32-AmariX))/32 , territoryY = (Image.size.height+(32-AmariY))/32;
    int LimitX = territoryX , LimitY = territoryY;
    int territory = territoryX * territoryY , mojidata[1024] = {0};
    int black = 0 , startX = 0 , startY = 0 ;
    float per;
    NSMutableArray *str=[[NSMutableArray alloc]init];
    UInt8 b = 0;
    NSString *str1=@"";
    
    for (int i=1; i <= 1024; i++) {
        
        for (int x=startX; x < LimitX; x++) {
            
            for (int y=startY; y < LimitY; y++) {
                
                int pixX = x + left,pixY = y + top;
                if(pixX >= 255 || pixY >= 255){
                    if (pixX >= 255){
                        if (pixY >= 255)b = 1;
                        else b = *(pixelPtr2[x][pixY] + 0);
                    }
                    if (pixY >= 255){
                        if (pixX >= 255)b = 1;
                        else b = *(pixelPtr2[pixX][y] + 0);
                    }
                }else{
                    b = *(pixelPtr2[pixX][pixY] + 0);
                }
                if (b == 0) {
                    black++;
                }
                
            }
            
        }
        per = (float)black/(float)territory;
        black = 0;
        if ( per > 0.1 ) {
            mojidata[i-1] = 1;
        }
        if (i%32 != 0) {
            LimitX += territoryX;
            startX += territoryX;
            
        }else{
            startX = 0;
            LimitX = territoryX;
            LimitY += territoryY;
            startY += territoryY;
            
        }
        
        NSString *add = [NSString stringWithFormat:@"%d",mojidata[i-1]];
        NSString *add2 = [NSString stringWithFormat:@",%d",mojidata[i-1]];
        str1 = [str1 stringByAppendingString:add2];
        [str addObject:add];
        
    }
    NSString *filePath = [NSString stringWithFormat:@"%@/moji.txt" , [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]];
    NSData *mojiData = [str1 dataUsingEncoding:NSUTF8StringEncoding];
    [mojiData writeToFile:filePath atomically:YES];
    
    return str;
}

- (NSMutableArray*)ParseJson{
    
    NSMutableArray *MojiData=[[NSMutableArray alloc]init];

    // JSONを読み込む
    NSError *error0 = nil;
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource:@"aiueo" ofType:@"json"];
    NSString *jsonString = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error: &error0];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUnicodeStringEncoding];
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    if(error0)NSLog(@"よみこみえらー");

    for (int i=0; i<65536; i++) {
        NSString *num = [NSString stringWithFormat:@"%d",i];
        NSDictionary *jsDic = [jsonDictionary objectForKey:num];
        if (jsDic!=NULL) {
            [MojiData addObject:jsDic];
        }
    }
    return MojiData;
}

/*-(void)ParceMessagePack{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource:@"aiueo" ofType:@"msgpack"];
    NSData* myData = [[NSData alloc] initWithContentsOfFile:path];
    NSDictionary* parsed = [myData messagePackParse];
    NSLog(@"%@", [parsed description]);

}*/

-(void)findMoji:(NSMutableArray*)tegakiData{

    int point=0;
    int max=0;
    NSString *maxindex;
    NSInteger mojic=[MojiData count];
    
    for (int j=0; j<mojic; j++) {
        for (int i=0; i<1024; i++) {
            NSString *m = [NSString stringWithFormat:@"%@",MojiData[j][0][1][i]];
            NSString *t = [NSString stringWithFormat:@"%@",tegakiData[i]];
            long mm = m.integerValue;
            long tt = t.integerValue;
            if (mm==tt) {
                point++;
            }
        }
        if (point>max) {
            max=point;
            maxindex=[NSString stringWithFormat:@"%@",MojiData[j][0][0]];
        }
        point=0;
    }
    NSLog(@"moji->%@:%d",maxindex,max);
    _label.text=maxindex;
    
}

@end
