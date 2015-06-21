

#import <UIKit/UIKit.h>
#import "SVProgressHUD.h"

@interface ViewController : UIViewController
<UIPopoverControllerDelegate,UISplitViewControllerDelegate> {
    UIPopoverController *popoverController;
    UIToolbar *toolbar;
    id detailItem;
    UILabel *detailDescriptionLabel;
    CGPoint touchPoint;
}
@end

