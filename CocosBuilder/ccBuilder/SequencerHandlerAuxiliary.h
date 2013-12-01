//
//  SequencerHandlerAuxiliary.h
//  CocosBuilder
//
//  Created by 朱 巍 on 30/11/13.
//
//

#import <Foundation/Foundation.h>

@interface SequencerHandlerAuxiliary : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate> {
    NSOutlineView *outlineStructure;
}

@property (nonatomic,assign) BOOL dragAndDropEnabled;

@property (nonatomic,readonly) NSOutlineView* outlineStructure;

+ (SequencerHandlerAuxiliary *) sharedHandlerAuxiliary;

- (instancetype) initWithOutlineView:(NSOutlineView *)view;

@end
