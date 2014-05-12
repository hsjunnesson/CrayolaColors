//
//  ColorPickerTableViewController.m
//  Crayola Colors
//
//  Created by Hans Sjunnesson on 2014-05-12.
//  Copyright (c) 2014 Hans Sjunnesson. All rights reserved.
//

#import "ColorPickerTableViewController.h"


@interface ColorPickerTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *swatch;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *hexLabel;

@end

@implementation ColorPickerTableViewCell

@end


#pragma mark - 

@interface ColorPickerTableViewController ()

@property (strong) RACSignal *colorsSignal;
@property (strong) NSArray *contents;
@property (readwrite, strong) RACSubject *selectionSignal;

@end


@implementation ColorPickerTableViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.selectionSignal = [RACSubject subject];
    
    self.colorsSignal = [RACReplaySubject replaySubjectWithCapacity:1];
    [((RACSubject *)self.colorsSignal) sendNext:nil];
    
    // Fetch json
    {
        @weakify(self);
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://gist.githubusercontent.com/jjdelc/1868136/raw/c734ad88bb3b5a2b27f4e91a24716024c66da421/crayola.json"]];
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   @strongify(self);
                                   
                                   if (!connectionError) {
                                       NSError *error = nil;
                                       NSArray *colors = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                                       
                                       if (colors)
                                           [((RACSubject *)self.colorsSignal) sendNext:colors];
                                       else
                                           [((RACSubject *)self.colorsSignal) sendError:error];
                                   } else {
                                       [((RACSubject *)self.colorsSignal) sendError:connectionError];
                                   }
                               }];
        
        // Subscribe to first data update
        [[[self.colorsSignal
          filter:^BOOL(id value) {
              return nil != value && [value class] != [NSNull class];
          }]
          take:1]
          subscribeNext:^(NSArray *colors) {
              @strongify(self);
              
              [self.tableView beginUpdates];
              [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];

              NSMutableArray *indexPaths = [NSMutableArray array];
              [colors enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                  [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
              }];

              [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
              
              self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
              
              self.contents = colors;
              
              [self.tableView endUpdates];
          } error:^(NSError *error) {
              [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Something went wrong!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
              
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                  @strongify(self);
                  [self.navigationController popViewControllerAnimated:YES];
              });
          }];
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *colors = self.contents;
    
    if (colors)
        return [colors count];
    else
        return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *colors = self.contents;
    
    if (colors)
        return [tableView dequeueReusableCellWithIdentifier:@"ColorCell" forIndexPath:indexPath];
    else
        return [tableView dequeueReusableCellWithIdentifier:@"LoadingCell" forIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *colors = self.contents;
    
    if (colors)
        return 80.0f;
    else
        return 61.0f;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *colors = self.contents;
    
    if (colors) {
        ColorPickerTableViewCell *colorPickerCell = (ColorPickerTableViewCell *)cell;
        colorPickerCell.swatch.layer.cornerRadius = 10.0f;
        
        RACTuple *tuple = [self colorAtIndexPath:indexPath];
        RACTupleUnpack(NSString *name, NSString *hex, UIColor *color) = tuple;
        
        colorPickerCell.nameLabel.text = name;
        colorPickerCell.hexLabel.text = hex;
        colorPickerCell.swatch.backgroundColor = color;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [((RACSubject *)self.selectionSignal) sendNext:[self colorAtIndexPath:indexPath]];
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Helpers

- (RACTuple *)colorAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *colors = self.contents;
    
    if (colors) {
        NSDictionary *color = colors[indexPath.row];
        
        NSString *name = color[@"name"];
        NSString *hex = color[@"hex"];
        NSString *rgb = color[@"rgb"];
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\((.+),[ ]?(.+),[ ]?(.+)\\)$" options:0 error:nil];
        NSArray *matches = [regex matchesInString:rgb options:0 range:NSMakeRange(0, [rgb length])];
        
        UIColor *rgbColor = [UIColor blackColor];
        
        if ([matches count] == 1) {
            NSTextCheckingResult *match = matches[0];
            if ([match numberOfRanges] == 4) {
                NSMutableArray *components = [NSMutableArray array];
                
                for (int i = 1; i < 4; i++)
                    [components addObject:[rgb substringWithRange:[match rangeAtIndex:i]]];
                
                rgbColor = [UIColor colorWithRed:[components[0] floatValue]/255.0f
                                           green:[components[1] floatValue]/255.0f
                                            blue:[components[2] floatValue]/255.0f
                                           alpha:1.0f];
            }
        }
        
        return RACTuplePack(name, hex, rgbColor);
    }
    
    return nil;
}

@end
