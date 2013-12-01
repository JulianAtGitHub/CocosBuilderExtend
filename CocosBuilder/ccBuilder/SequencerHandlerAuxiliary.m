//
//  SequencerHandlerAuxiliary.m
//  CocosBuilder
//
//  Created by 朱 巍 on 30/11/13.
//
//

#import "SequencerHandlerAuxiliary.h"
#import "CCBGlobals.h"
#import "NodeInfo.h"
#import "PlugInNode.h"
#import "CCNode+NodeInfo.h"

static SequencerHandlerAuxiliary *sharedSequencerHandlerAuxiliary = nil;

@implementation SequencerHandlerAuxiliary

@synthesize dragAndDropEnabled;
@synthesize outlineStructure;

+ (SequencerHandlerAuxiliary *) sharedHandlerAuxiliary
{
    return sharedSequencerHandlerAuxiliary;
}

- (instancetype) initWithOutlineView:(NSOutlineView *)view
{
    self = [super init];
    if (!self) return nil;
    
    sharedSequencerHandlerAuxiliary = self;
    
    outlineStructure = view;
    
    [outlineStructure setDataSource:self];
    [outlineStructure setDelegate:self];
    [outlineStructure reloadData];
    
    return self;
}

#pragma mark Outline View Data Source

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if ([[CCBGlobals globals] rootNode] == NULL) return 0;
    if (item == nil) return 1;
    
    CCNode* node = (CCNode*)item;
    CCArray* arr = [node children];
    
    return [arr count];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    CCBGlobals* g= [CCBGlobals globals];
    
    if (item == nil)
    {
        return g.rootNode;
    }
    
    CCNode* node = (CCNode*)item;
    CCArray* arr = [node children];
    return [arr objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (item == nil) return YES;
    
    CCNode* node = (CCNode*)item;
    CCArray* arr = [node children];
    NodeInfo* info = node.userObject;
    PlugInNode* plugIn = info.plugIn;
    
    if ([arr count] == 0) return NO;
    if (!plugIn.canHaveChildren) return NO;
    
    return YES;
}
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if (item == nil) return @"Root";
    
    CCNode* node = item;
    return node.displayName;
}

@end
