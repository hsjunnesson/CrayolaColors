//
//  ColorPickerTableViewController.h
//  Crayola Colors
//
//  Created by Hans Sjunnesson on 2014-05-12.
//  Copyright (c) 2014 Hans Sjunnesson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ColorPickerTableViewController : UITableViewController

// Sends a RACTuple of a color's name, hex code and color as a NSString, NSString and UIColor.
@property (readonly, strong) RACSignal *selectionSignal;

@end
