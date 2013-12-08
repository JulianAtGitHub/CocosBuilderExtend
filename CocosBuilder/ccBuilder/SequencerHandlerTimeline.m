//
//  SequencerHandlerTimeline.m
//  CocosBuilder
//
//  Created by wei.zhu on 12/3/13.
//
//

#import "SequencerHandlerTimeline.h"
#import "SequencerHandler.h"
#import "CCBGlobals.h"
#import "NodeInfo.h"
#import "CCNode+NodeInfo.h"
#import "PlugInNode.h"
#import "CocosBuilderAppDelegate.h"
#import "SequencerSequence.h"
#import "SequencerScrubberSelectionView.h"
#import "SequencerExpandBtnCell.h"
#import "SequencerCell.h"
#import "SequencerStructureCell.h"
#import "SequencerKeyframe.h"
#import "SequencerKeyframeEasing.h"
#import "CCBDocument.h"

static SequencerHandlerTimeline *sharedSequencerHandlerTimeline = nil;

@implementation SequencerHandlerTimeline

@synthesize dragAndDropEnabled;
@synthesize outlineTimeline;
@synthesize scroller;
@synthesize currentSequence;
@synthesize scrubberSelectionView;
@synthesize contextKeyframe;
@synthesize keyframeEasingType;
@synthesize keyframeEasingSlide;
@synthesize keyframeEasingDetailView;

+ (SequencerHandlerTimeline *) sharedHandlerTimeline
{
    return sharedSequencerHandlerTimeline;
}

- (instancetype) initWithOutlineView:(NSOutlineView *)view
{
    self = [super init];
    if (!self) return nil;
    
    appDelegate = [CocosBuilderAppDelegate appDelegate];
    
    sharedSequencerHandlerTimeline = self;
    
    outlineTimeline = view;
    
    [outlineTimeline setDataSource:self];
    [outlineTimeline setDelegate:self];
    [outlineTimeline reloadData];
    
    return self;
}

- (void) setContextKeyframe:(SequencerKeyframe *)keyframe
{
    if (contextKeyframe != keyframe)
    {
        [contextKeyframe release];
        contextKeyframe = [keyframe retain];
    }
    
    [self refreshKeyframeEasingDetail];
}

#pragma mark Easings

- (void) refreshKeyframeEasingDetail
{
    if (contextKeyframe && contextKeyframe.easing.hasOptions) {
        NSMenuItem* item = [appDelegate.menuContextKeyframeInterpol itemWithTag:contextKeyframe.easing.type];
        [keyframeEasingType setStringValue:[item title]];
        
        float optionValue = [contextKeyframe.easing.options floatValue];
        [keyframeEasingDetailView setHidden:NO];
        appDelegate.easingSlideValueMin = 0.0;
        appDelegate.easingSlideValueMax = 2.0 * optionValue;
        appDelegate.easingSlideValue = optionValue;
    } else {
        if (contextKeyframe) {
            NSMenuItem* item = [appDelegate.menuContextKeyframeInterpol itemWithTag:contextKeyframe.easing.type];
            [keyframeEasingType setStringValue:[item title]];
        } else {
            [keyframeEasingType setStringValue:@""];
        }
        [keyframeEasingDetailView setHidden:YES];
    }
}

#pragma mark Handle scroller

- (void) redrawTimeline:(BOOL) reload
{
    [scrubberSelectionView setNeedsDisplay:YES];
    [self updateScroller];
    if (reload) {
        [outlineTimeline reloadData];
    }
}

- (void) redrawTimeline
{
    [self redrawTimeline:YES];
}

- (void) setCurrentSequence:(SequencerSequence *)seq
{
    if (seq != currentSequence)
    {
        [currentSequence release];
        currentSequence = [seq retain];
        
        [outlineTimeline reloadData];
        [self redrawTimeline];
        [self updatePropertiesToTimelinePosition];
    }
}

- (SequencerSequence*) seqId:(int)seqId inArray:(NSArray*)array
{
    for (SequencerSequence* seq in array)
    {
        if (seq.sequenceId == seqId) return seq;
    }
    return NULL;
}

- (void) updatePropertiesToTimelinePositionForNode:(CCNode*)node sequenceId:(int)seqId localTime:(float)time
{
    [node updatePropertiesTime:time sequenceId:seqId];
    
    // Also deselect keyframes of children
    CCArray* children = [node children];
    CCNode* child = NULL;
    CCARRAY_FOREACH(children, child)
    {
        int childSeqId = seqId;
        float localTime = time;
        
        // Sub ccb files uses different sequence id:s
        NSArray* childSequences = [child extraPropForKey:@"*sequences"];
        int childStartSequence = [[child extraPropForKey:@"*startSequence"] intValue];
        
        if (childSequences && childStartSequence != -1)
        {
            childSeqId = childStartSequence;
            SequencerSequence* seq = [self seqId:childSeqId inArray:childSequences];
            
            while (localTime > seq.timelineLength && seq.chainedSequenceId != -1)
            {
                localTime -= seq.timelineLength;
                seq = [self seqId:seq.chainedSequenceId inArray:childSequences];
            }
        }
        
        [self updatePropertiesToTimelinePositionForNode:child sequenceId:childSeqId localTime:localTime];
    }
}

- (void) updatePropertiesToTimelinePosition
{
    [self updatePropertiesToTimelinePositionForNode:[[CocosScene cocosScene] rootNode] sequenceId:currentSequence.sequenceId localTime:currentSequence.timelinePosition];
}

- (void) setScroller:(NSScroller *)s
{
    if (s != scroller)
    {
        [scroller release];
        scroller = [s retain];
        
        [scroller setTarget:self];
        [scroller setAction:@selector(scrollerUpdated:)];
        
        [self updateScroller];
    }
}

- (void) scrollerUpdated:(id)sender
{
    float newOffset = currentSequence.timelineOffset;
    float visibleTime = [self visibleTimeArea];
    
    switch ([scroller hitPart]) {
        case NSScrollerNoPart:
            break;
        case NSScrollerDecrementPage:
            newOffset -= 300 / currentSequence.timelineScale;
            break;
        case NSScrollerKnob:
            newOffset = scroller.doubleValue * (currentSequence.timelineLength - visibleTime);
            break;
        case NSScrollerIncrementPage:
            newOffset += 300 / currentSequence.timelineScale;
            break;
        case NSScrollerDecrementLine:
            newOffset -= 20 / currentSequence.timelineScale;
            break;
        case NSScrollerIncrementLine:
            newOffset += 20 / currentSequence.timelineScale;
            break;
        case NSScrollerKnobSlot:
            newOffset = scroller.doubleValue * (currentSequence.timelineLength - visibleTime);
            break;
        default:
            break;
    }
    
    currentSequence.timelineOffset = newOffset;
}

- (float) visibleTimeArea
{
    NSTableColumn* column = [outlineTimeline tableColumnWithIdentifier:@"sequencer"];
    return (column.width-2*TIMELINE_PAD_PIXELS)/currentSequence.timelineScale;
}

- (float) maxTimelineOffset
{
    float visibleTime = [self visibleTimeArea];
    return max(currentSequence.timelineLength - visibleTime, 0);
}

- (void) updateScroller
{
    float visibleTime = [self visibleTimeArea];
    float maxTimeScroll = currentSequence.timelineLength - visibleTime;
    
    float proportion = visibleTime/currentSequence.timelineLength;
    
    scroller.knobProportion = proportion;
    scroller.doubleValue = currentSequence.timelineOffset / maxTimeScroll;
    
    if (proportion < 1)
    {
        [scroller setEnabled:YES];
    }
    else
    {
        [scroller setEnabled:NO];
    }
}

- (void) updateScrollerToShowCurrentTime
{
    float visibleTime = [self visibleTimeArea];
    float maxTimeScroll = [self maxTimelineOffset];
    float timelinePosition = currentSequence.timelinePosition;
    if (maxTimeScroll > 0)
    {
        float minVisibleTime = scroller.doubleValue*(currentSequence.timelineLength-visibleTime);
        float maxVisibleTime = scroller.doubleValue*(currentSequence.timelineLength-visibleTime) + visibleTime;
        
        if (timelinePosition < minVisibleTime) {
            scroller.doubleValue = timelinePosition/(currentSequence.timelineLength-visibleTime);
            currentSequence.timelineOffset = scroller.doubleValue * (currentSequence.timelineLength - visibleTime);
        } else if (timelinePosition > maxVisibleTime) {
            scroller.doubleValue = (timelinePosition-visibleTime)/(currentSequence.timelineLength-visibleTime);
            currentSequence.timelineOffset = scroller.doubleValue * (currentSequence.timelineLength - visibleTime);
        }
    }
}

#pragma mark Outline View Data Source
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if ([[CCBGlobals globals] rootNode] == NULL) return 0;
    if ([appDelegate.selectedNodes count]) {
        return 1;
    } else {
        return 0;
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    return [appDelegate.selectedNodes objectAtIndex:0];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if (item == nil) return @"Root";
    
    if ([tableColumn.identifier isEqualToString:@"sequencer"])
    {
        return @"";
    }
    
    CCNode* node = item;
    node.seqExpanded = YES;
//    return node.displayName;
    return @"";
}

#pragma mark Outline View Delegate

- (void) outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    CCNode* node = item;
    BOOL isRootNode = (node == [CocosScene cocosScene].rootNode);
    
    if ([tableColumn.identifier isEqualToString:@"expander"])
    {
        SequencerExpandBtnCell* expCell = cell;
        expCell.isExpanded = node.seqExpanded;
        expCell.canExpand = (!isRootNode);
        expCell.node = node;
    }
    else if ([tableColumn.identifier isEqualToString:@"structure"])
    {
        SequencerStructureCell* strCell = cell;
        strCell.node = node;
    }
    else if ([tableColumn.identifier isEqualToString:@"sequencer"])
    {
        SequencerCell* seqCell = cell;
        seqCell.node = node;
    }
}

- (CGFloat) outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    CCNode* node = item;
    return kCCBSeqDefaultRowHeight * ([[node.plugIn animatablePropertiesForNode:node] count]);
        
//    CCNode* node = item;
//    if (node.seqExpanded)
//    {
//        return kCCBSeqDefaultRowHeight * ([[node.plugIn animatablePropertiesForNode:node] count]);
//    }
//    else
//    {
//        return kCCBSeqDefaultRowHeight;
//    }
}

#pragma mark Outline View

- (void) toggleSeqExpanderForRow:(int)row
{
    id item = [outlineTimeline itemAtRow:row];
    
    CCNode* node = item;
    
    if (node == [CocosScene cocosScene].rootNode && !node.seqExpanded) return;
    //if ([NSStringFromClass(node.class) isEqualToString:@"CCBPCCBFile"] && !node.seqExpanded) return;
    
    //node.seqExpanded = !node.seqExpanded;
    node.seqExpanded = YES;
    
    // Need to reload all data when changing heights of rows
    [outlineTimeline reloadData];
}

#pragma mark Destructor

- (void) dealloc
{
    self.currentSequence = nil;
    self.scrubberSelectionView = nil;
    
    [super dealloc];
}

@end
