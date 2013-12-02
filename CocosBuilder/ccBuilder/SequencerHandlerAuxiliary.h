//
//  SequencerHandlerAuxiliary.h
//  CocosBuilder
//
//  Created by 朱 巍 on 30/11/13.
//
//

#import <Foundation/Foundation.h>

@class CCNode;
@class CocosBuilderAppDelegate;

@interface SequencerHandlerAuxiliary : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate> {
    CocosBuilderAppDelegate *appDelegate;
    NSOutlineView *outlineStructure;
}

@property (nonatomic,assign) BOOL dragAndDropEnabled;

@property (nonatomic,readonly) NSOutlineView *outlineStructure;

+ (SequencerHandlerAuxiliary *) sharedHandlerAuxiliary;

- (instancetype) initWithOutlineView:(NSOutlineView *)view;

- (void) updateOutlineViewSelection;
- (void) updateExpandedForNode:(CCNode *)node;

@end
