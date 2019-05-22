//
//  OSTRightMenuViewController.m
//  OST Tracker
//
//  Created by Luciano Castro on 6/15/17.
//  Copyright © 2017 OST. All rights reserved.
//

#import "OSTRightMenuViewController.h"
#import "OSTEventSelectionViewController.h"
#import "OSTRunnerTrackerViewController.h"
#import "OSTCrossCheckViewController.h"
#import "UIView+Additions.h"
#import "OSTSyncManager.h"
#import "CurrentCourse.h"
#import "EntryModel.h"

@interface OSTRightMenuViewController () <OSTSyncManagerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *rightMenuBackImage;
@property (weak, nonatomic) IBOutlet UIView *coverView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *syncIndicator;
@property (weak, nonatomic) IBOutlet UILabel *lblBadge;
@property (nonatomic,strong) IBOutletCollection(UIView) NSArray *buttonViews;
@property (nonatomic,strong) IBOutletCollection(UIView) NSArray *separatorViews;
@end

@implementation OSTRightMenuViewController

- (void)dealloc
{
    [[[OSTSyncManager shared] delegates] removeObject:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.buttonViews = [self sortOutletCollectionByTag:self.buttonViews];
    self.separatorViews = [self sortOutletCollectionByTag:self.separatorViews];
    
    [[[OSTSyncManager shared] delegates] addObject:self];
    // Do any additional setup after loading the view from its nib.
    self.scrollView.contentSize = CGSizeMake(0, 668);
    if(IS_IPHONE_5)
    {
        [self rearrangeViews];
    }
    
    self.lblBadge.layer.cornerRadius = self.lblBadge.width/2;
    self.lblBadge.clipsToBounds = YES;
    [self updateSyncBadge];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.syncIndicator setHidden:![[OSTSyncManager shared] isSyncing]];
    [self updateSyncBadge];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)rearrangeViews
{
    self.rightMenuBackImage.height = 668;
    self.rightMenuBackImage.width = 350;
    self.rightMenuBackImage.top = 30;
    self.coverView.top = -90;
    self.coverView.height = 1000;
    
    CGFloat margin = 10;
    CGFloat nextY = 0;
    
    for (int i = 0; i<self.buttonViews.count; i++)
    {
        UIView *buttonView = self.buttonViews[i];
        UIButton *button;
        if ([buttonView isKindOfClass:[UIButton class]])
        {
            button = (UIButton *)buttonView;
        }
        else
        {
            for (UIView *view in buttonView.subviews)
            {
                if ([view isKindOfClass:[UIButton class]])
                {
                    button = (UIButton *)view;
                    break;
                }
            }
        }
        
        if (button != nil)
        {
            [button.titleLabel setFont:[UIFont fontWithName:button.titleLabel.font.familyName size:25]];
        }
        
        if (i > 0)
        {
            buttonView.top = nextY;
        }
        
        if (i < self.separatorViews.count)
        {
            UIView *separator = self.separatorViews[i];
            separator.top = buttonView.bottom + margin;
            nextY = separator.bottom + margin;
        }
        
    }
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, nextY);
}

- (IBAction)onClose:(id)sender
{
    [[AppDelegate getInstance].rightMenuVC toggleRightSideMenuCompletion:nil];
    
    if ([[AppDelegate getInstance].rightMenuVC.centerViewController isKindOfClass:[OSTRunnerTrackerViewController class]])
    {
        [((OSTRunnerTrackerViewController*)([AppDelegate getInstance].rightMenuVC.centerViewController)).txtBibNumber becomeFirstResponder];
    }
}

- (IBAction)onCrossCheck:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"CrossCheck" bundle:nil];
    UIViewController *controller = [storyboard instantiateInitialViewController];
    
    [AppDelegate getInstance].rightMenuVC.centerViewController = controller;
    [[AppDelegate getInstance].rightMenuVC toggleRightSideMenuCompletion:nil];
}

- (IBAction)onSubmit:(id)sender
{
    [[AppDelegate getInstance] showTracker];
    [[AppDelegate getInstance].rightMenuVC toggleRightSideMenuCompletion:nil];
}

- (IBAction)onChangeStation:(id)sender
{
    //[[AppDelegate getInstance].rightMenuVC switchRightMenu:NO];
    OSTEventSelectionViewController * event = [[OSTEventSelectionViewController alloc] initWithNibName:nil bundle:nil];
    event.changeStation = YES;
    [self presentViewController:event animated:YES completion:nil];
}

- (IBAction)onReviewSync:(id)sender
{
    [[AppDelegate getInstance] showReview];
    [[AppDelegate getInstance].rightMenuVC toggleRightSideMenuCompletion:nil];
}

- (IBAction)onLogout:(id)sender
{
    if (![AppDelegate getInstance].getNetworkManager.reachabilityManager.reachable)
    {
        [OHAlertView showAlertWithTitle:@"Logout is disabled" message:@"Please try again when you have an Internet connection" cancelButton:@"Ok" otherButtons:nil buttonHandler:nil];
        return;
    }
    
    [OHAlertView showAlertWithTitle:@"Are you sure you would like to log out?" message:@"You will not be able to log back in or add entries until you have a data connection again." cancelButton:@"Cancel" otherButtons:@[@"Logout"] buttonHandler:^(OHAlertView *alert, NSInteger buttonIndex) {
        if (buttonIndex == 1)
        {
            [[AppDelegate getInstance].rightMenuVC toggleRightSideMenuCompletion:nil];
            [[AppDelegate getInstance] logout];
        }
    }];
}

#pragma mark - OSTSyncManagerDelegate

- (void)syncManagerDidStartSynchronization:(OSTSyncManager *)manager
{
    [self.syncIndicator setHidden:NO];
    [self updateSyncBadge];
}

- (void)syncManager:(OSTSyncManager *)manager progress:(CGFloat)progress
{
    
}

- (void)syncManagerDidFinishSynchronization:(OSTSyncManager *)manager
{
    [self.syncIndicator setHidden:YES];
    [self updateSyncBadge];
}

- (void)syncManager:(OSTSyncManager *)manager didFinishSynchronizationWithErrors:(NSArray<NSError *> *)errors alternateServer:(BOOL)alternateServer
{
    [self.syncIndicator setHidden:YES];
    [self updateSyncBadge];
}

- (void)updateSyncBadge
{
    NSMutableArray * entries = [EntryModel MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"combinedCourseId == %@ && submitted == NIL && bibNumber != %@",[CurrentCourse getCurrentCourse].eventId,@"-1"]].mutableCopy;
    if (entries.count == 0)
    {
        self.lblBadge.hidden = YES;
    }
    else
    {
        self.lblBadge.hidden = NO;
        self.lblBadge.text = [NSString stringWithFormat:@"%@",@(entries.count)];
        
        if (self.lblBadge.text.length == 1)
        {
            self.lblBadge.width = self.lblBadge.height;
        }
        else
        {
            CGRect badgeSize = [self.lblBadge.text boundingRectWithSize:CGSizeMake(FLT_MAX, self.lblBadge.height) options:0 attributes:@{NSFontAttributeName:self.lblBadge.font} context:nil];
            CGFloat padding = 8;
            self.lblBadge.width = badgeSize.size.width + padding * 2;
        }
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSArray *)sortOutletCollectionByTag:(NSArray *)views
{
    return [views sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"tag" ascending:YES]]];
}

@end
