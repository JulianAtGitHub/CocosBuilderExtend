//
//  SequencerHandlerStructure.m
//  CocosBuilder
//
//  Created by 朱 巍 on 30/11/13.
//
//

#import "SequencerHandlerStructure.h"
#import "CocosBuilderAppDelegate.h"
#import "CCBGlobals.h"
#import "NodeInfo.h"
#import "PlugInNode.h"
#import "CCNode+NodeInfo.h"
#import "SequencerScrubberSelectionView.h"

static SequencerHandlerStructure *sharedSequencerHandlerStructure = nil;

@implementation SequencerHandlerStructure

@synthesize dragAndDropEnabled;
@synthesize outlineStructure;

+ (SequencerHandlerStructure *) sharedHandlerAuxiliary
{
    return sharedSequencerHandlerStructure;
}

- (instancetype) initWithOutlineView:(NSOutlineView *)view
{
    self = [super init];
    if (!self) return nil;
    
    appDelegate = [CocosBuilderAppDelegate appDelegate];
    
    sharedSequencerHandlerStructure = self;
    
    outlineStructure = view;
    
    [outlineStructure setDataSource:self];
    [outlineStructure setDelegate:self];
    [outlineStructure reloadData];
    
    return self;
}

#pragma mark Update Outline view

- (void) updateOutlineViewSelection
{
    if (!appDelegate.selectedNodes.count)
    {
        [outlineStructure selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
        return;
    }
    CCBGlobals* g = [CCBGlobals globals];
    
    // Expand parents of the selected node
    CCNode* node = [appDelegate.selectedNodes objectAtIndex:0];
    NSMutableArray* nodesToExpand = [NSMutableArray array];
    while (node != g.rootNode && node != NULL)
    {
        [nodesToExpand insertObject:node atIndex:0];
        node = node.parent;
    }
    for (int i = 0; i < [nodesToExpand count]; i++)
    {
        node = [nodesToExpand objectAtIndex:i];
        [outlineStructure expandItem:node.parent];
    }
    
    // Update the selection
    NSMutableIndexSet* indexes = [NSMutableIndexSet indexSet];
    
    for (CCNode* selectedNode in appDelegate.selectedNodes)
    {
        int row = (int)[outlineStructure rowForItem:selectedNode];
        [indexes addIndex:row];
    }
    [outlineStructure selectRowIndexes:indexes byExtendingSelection:NO];
}

- (void) updateExpandedForNode:(CCNode*)node
{
    if ([self outlineView:outlineStructure isItemExpandable:node])
    {
        bool expanded = [[node extraPropForKey:@"isExpanded"] boolValue];
        if (expanded) [outlineStructure expandItem:node];
        else [outlineStructure collapseItem:node];
        
        CCArray* childs = [node children];
        for (int i = 0; i < [childs count]; i++)
        {
            CCNode* child = [childs objectAtIndex:i];
            [self updateExpandedForNode:child];
        }
    }
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

#pragma mark Outline view Delegate

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    NSIndexSet* indexes = [outlineStructure selectedRowIndexes];
    NSMutableArray* selectedNodes = [NSMutableArray array];
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        id item = [outlineStructure itemAtRow:idx];
        CCNode* node = item;
        [selectedNodes addObject:node];
    }];
    
    appDelegate.selectedNodes = selectedNodes;
    
    [appDelegate updateInspectorFromSelection];
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
    CCNode* node = [[notification userInfo] objectForKey:@"NSObject"];
    [node setExtraProp:[NSNumber numberWithBool:NO] forKey:@"isExpanded"];
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
    CCNode* node = [[notification userInfo] objectForKey:@"NSObject"];
    [node setExtraProp:[NSNumber numberWithBool:YES] forKey:@"isExpanded"];
}

#pragma mark Destructor

- (void) dealloc
{
    [super dealloc];
}

@end
