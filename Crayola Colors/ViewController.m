//
//  ViewController.m
//  Crayola Colors
//
//  Created by Hans Sjunnesson on 2014-05-12.
//  Copyright (c) 2014 Hans Sjunnesson. All rights reserved.
//

#import "ViewController.h"
#import "ColorPickerTableViewController.h"


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *selectButton;
@property (weak, nonatomic) IBOutlet UILabel *selectColorLabel;
@property (weak, nonatomic) IBOutlet UILabel *hexLabel;

@end


@implementation ViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.selectButton.layer.cornerRadius = 10.0f;
}

- (IBAction)selectColorAction:(id)sender {
    @weakify(self);
    
    RACSignal *fadeToGray = [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        CATransition *animation = [CATransition animation];
        animation.duration = 0.5f;
        animation.type = kCATransitionFade;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

        [self.selectButton.layer addAnimation:animation forKey:@"transition"];
        self.selectButton.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];

        [subscriber sendCompleted];
        
        return nil;
    }]
    delay:0.5f]
    subscribeOn:RACScheduler.mainThreadScheduler];
    
    RACSignal *selectColor = [[[[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        ColorPickerTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ColorPicker"];
        
        [self.navigationController pushViewController:vc animated:YES];
        
        [subscriber sendNext:vc];
        [subscriber sendCompleted];
        
        return nil;
    }]
    flattenMap:^RACStream *(ColorPickerTableViewController *vc) {
        return [vc.selectionSignal take:1];
    }]
    delay:0.5f]
    flattenMap:^RACStream *(RACTuple *tuple) {
        return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            @strongify(self);
            RACTupleUnpack(NSString *name, NSString *hex, UIColor *color) = tuple;
            
            CATransition *animation = [CATransition animation];
            animation.duration = 0.5f;
            animation.type = kCATransitionFade;
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            [self.selectColorLabel.layer addAnimation:animation forKey:@"transition"];
            [self.selectButton.layer addAnimation:animation forKey:@"transition"];
            [self.hexLabel.layer addAnimation:animation forKey:@"transition"];
            
            self.selectColorLabel.text = name;
            self.selectButton.backgroundColor = color;
            self.hexLabel.text = hex;
            self.hexLabel.alpha = 1.0;
            
            [subscriber sendCompleted];
            return nil;
        }] delay:0.5f];
    }]
    subscribeOn:RACScheduler.mainThreadScheduler];
    
    RACSignal *animationSteps = [[[@[[fadeToGray delay:0.3f], selectColor]
                                     rac_sequence]
                                     signal]
                                     concat];
    
    [animationSteps subscribeCompleted:^{
        // Done
    }];
}

@end
