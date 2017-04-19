//
//Copyright (c) 2011, Tim Cinel
//All rights reserved.
//
//Redistribution and use in source and binary forms, with or without
//modification, are permitted provided that the following conditions are met:
//* Redistributions of source code must retain the above copyright
//notice, this list of conditions and the following disclaimer.
//* Redistributions in binary form must reproduce the above copyright
//notice, this list of conditions and the following disclaimer in the
//documentation and/or other materials provided with the distribution.
//* Neither the name of the <organization> nor the
//names of its contributors may be used to endorse or promote products
//derived from this software without specific prior written permission.
//
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
//DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//åLOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "ActionSheetDualPicker.h"

@interface ActionSheetDualPicker()
@property (nonatomic,strong) NSArray *data;
@property (nonatomic,assign) NSInteger selectedIndex;

@property (nonatomic,strong) NSMutableDictionary *dataDictionary;

@property (nonatomic,strong) NSMutableArray *firstColumn; // Array of strings
@property (nonatomic,strong) NSMutableArray *secondColumn; // Array of array of strings

@property (nonatomic,strong) NSString *selectedFirstColumnValue;
@property (nonatomic,strong) NSString *selectedSecondColumnValue;
@end

@implementation ActionSheetDualPicker

+ (instancetype)showPickerWithTitle:(NSString *)title rows:(NSArray *)data doneBlock:(ActionDualDoneBlock)doneBlock cancelBlock:(ActionDualCancelBlock)cancelBlockOrNil origin:(id)origin
{
    ActionSheetDualPicker * picker = [[ActionSheetDualPicker alloc] initWithTitle:title rows:data doneBlock:doneBlock cancelBlock:cancelBlockOrNil origin:origin];
    [picker showActionSheetPicker];
    return picker;
}

- (instancetype)initWithTitle:(NSString *)title rows:(NSArray *)data doneBlock:(ActionDualDoneBlock)doneBlock cancelBlock:(ActionDualCancelBlock)cancelBlockOrNil origin:(id)origin
{
    self = [self initWithTitle:title rows:data target:nil successAction:nil cancelAction:nil origin:origin];
    if (self) {
        self.data = data;
        self.onActionSheetDone = doneBlock;
        self.onActionSheetCancel = cancelBlockOrNil;
    }
    return self;
}

+ (instancetype)showPickerWithTitle:(NSString *)title rows:(NSArray *)data target:(id)target successAction:(SEL)successAction cancelAction:(SEL)cancelActionOrNil origin:(id)origin
{
    ActionSheetDualPicker *picker = [[ActionSheetDualPicker alloc] initWithTitle:title rows:data target:target successAction:successAction cancelAction:cancelActionOrNil origin:origin];
    [picker showActionSheetPicker];
    return picker;
}

- (instancetype)initWithTitle:(NSString *)title rows:(NSArray *)data target:(id)target successAction:(SEL)successAction cancelAction:(SEL)cancelActionOrNil origin:(id)origin
{
    self = [self initWithTarget:target successAction:successAction cancelAction:cancelActionOrNil origin:origin];
    if (self) {
        self.data = data;
        self.title = title;
    }
    return self;
}


- (UIView *)configuredPickerView {
    [self fillFirstAndSecondColumns];
    [self setSelectedRows];
    
    CGRect pickerFrame = CGRectMake(0, 40, self.viewSize.width, 216);
    UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
    pickerView.delegate = self;
    pickerView.dataSource = self;
    
    pickerView.showsSelectionIndicator = YES;
    
    [self setInitialValue:pickerView];
    
    //need to keep a reference to the picker so we can clear the DataSource / Delegate when dismissing
    self.pickerView = pickerView;
    
    return pickerView;
}

- (void)setInitialValue:(UIPickerView *)pickerView
{
    [pickerView selectRow:0 inComponent:0 animated:YES];
    [pickerView selectRow:0 inComponent:1 animated:YES];
}

-(void)fillFirstAndSecondColumns
{
    _firstColumn = [[NSMutableArray alloc] init];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for (int i = 0; i < [_data[0] count]; ++i) {
        [_firstColumn addObject:_data[0][i]];
        dict[_firstColumn[i]] = _data[1];
    }
    
    self.dataDictionary = dict;
};

- (void)setSelectedRows
{
    self.selectedFirstColumnValue = _firstColumn[0];
    self.selectedSecondColumnValue = [self getSecondColumnValues:self.selectedFirstColumnValue][0];
}


- (void)notifyTarget:(id)target didSucceedWithAction:(SEL)successAction origin:(id)origin {
    
    if (self.onActionSheetDone) {
        _onActionSheetDone(self, [self selectedIndexes], [self selection]);
        return;
    }
    else if (target && [target respondsToSelector:successAction]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [target performSelector:successAction withObject:self.selectedIndexes withObject:origin];
#pragma clang diagnostic pop
        return;
    }
    NSLog(@"Invalid target/action ( %s / %s ) combination used for ActionSheetPicker", object_getClassName(target), sel_getName(successAction));
}

- (void)notifyTarget:(id)target didCancelWithAction:(SEL)cancelAction origin:(id)origin {
    if (self.onActionSheetCancel) {
        _onActionSheetCancel(self);
        return;
    }
    else if (target && cancelAction && [target respondsToSelector:cancelAction]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [target performSelector:cancelAction withObject:origin];
#pragma clang diagnostic pop
    }
}

#pragma mark - UIPickerViewDelegate / DataSource
//
//- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
//    id obj = [self.data objectAtIndex:(NSUInteger) row];
//
//    // return the object if it is already a NSString,
//    // otherwise, return the description, just like the toString() method in Java
//    // else, return nil to prevent exception
//
//    if ([obj isKindOfClass:[NSString class]])
//        return obj;
//
//    if ([obj respondsToSelector:@selector(description)])
//        return [obj performSelector:@selector(description)];
//
//    return nil;
//}
//


/////////////////////////////////////////////////////////////////////////
#pragma mark - UIPickerViewDataSource Implementation
/////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    // Returns
    switch (component) {
        case 0: return [_firstColumn count];
        case 1: return [[self getSecondColumnValues:self.selectedFirstColumnValue] count];
        default:break;
    }
    return 0;
}

/////////////////////////////////////////////////////////////////////////
#pragma mark UIPickerViewDelegate Implementation
/////////////////////////////////////////////////////////////////////////

// returns width of column and height of row for each component.
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    
    switch (component) {
            
        case 0: return dualFirstColumnWidth;
        case 1: return dualSecondColumnWidth;
        default:break;
    }
    
    return 0;
}

- (UIView *)pickerView:(UIPickerView *)pickerView
            viewForRow:(NSInteger)row
          forComponent:(NSInteger)component
           reusingView:(UIView *)view {
    
    UILabel *pickerLabel = (UILabel *)view;
    
    if (pickerLabel == nil) {
        CGRect frame = CGRectZero;
        
        switch (component) {
            case 0: frame = CGRectMake(0.0, 0.0, dualFirstColumnWidth, 32);
                break;
            case 1:
                frame = CGRectMake(0.0, 0.0, dualSecondColumnWidth, 32);
                break;
            default:
                assert(NO);
                break;
        }
        
        pickerLabel = [[UILabel alloc] initWithFrame:frame];
        [pickerLabel setTextAlignment:NSTextAlignmentCenter];
        if ([pickerLabel respondsToSelector:@selector(setMinimumScaleFactor:)])
            [pickerLabel setMinimumScaleFactor:0.5];
        [pickerLabel setAdjustsFontSizeToFitWidth:YES];
        [pickerLabel setBackgroundColor:[UIColor clearColor]];
        [pickerLabel setFont:[UIFont systemFontOfSize:20]];
    }
    
    NSString *text;
    switch (component) {
        case 0: {
            text = (self.firstColumn)[(NSUInteger) row];
            break;
        }
        case 1:
        {
            text = [self getSecondColumnValues:self.selectedFirstColumnValue][(NSUInteger) row];
            break;
        }
        default:break;
    }
    
    [pickerLabel setText:text];
    
    return pickerLabel;
    
}

/////////////////////////////////////////////////////////////////////////

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    switch (component) {
        case 0:
        {
            self.selectedFirstColumnValue = (self.firstColumn)[(NSUInteger) row];
            [pickerView reloadComponent:1];
            self.selectedSecondColumnValue = [self getSecondColumnValues:self.selectedFirstColumnValue][(NSUInteger) [pickerView selectedRowInComponent:1]];
            return;
        }
            
        case 1:
            self.selectedSecondColumnValue = [self getSecondColumnValues:self.selectedFirstColumnValue][(NSUInteger) row];
            return;
        default:break;
    }
}

-(NSMutableArray *)getSecondColumnValues:(NSString *)firstColumnValue
{
    NSMutableArray *secondValuesInFirst = _dataDictionary[firstColumnValue];
    return secondValuesInFirst;
};

- (NSArray *)selection {
    NSMutableArray * array = [NSMutableArray array];
    for (int i = 0; i < self.data.count; i++) {
        id object = self.data[i][[(UIPickerView *)self.pickerView selectedRowInComponent:(NSInteger)i]];
        [array addObject: object];
    }
    return [array copy];
}

- (NSArray *)selectedIndexes {
    NSMutableArray * indexes = [NSMutableArray array];
    for (int i = 0; i < self.data.count; i++) {
        NSNumber *index = [NSNumber numberWithInteger:[(UIPickerView *)self.pickerView selectedRowInComponent:(NSInteger)i]];
        [indexes addObject: index];
    }
    return [indexes copy];
}


@end
