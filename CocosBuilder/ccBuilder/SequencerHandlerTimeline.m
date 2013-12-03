//
//  SequencerHandlerTimeline.m
//  CocosBuilder
//
//  Created by wei.zhu on 12/3/13.
//
//

#import "SequencerHandlerTimeline.h"
#import "CCBGlobals.h"
#import "NodeInfo.h"
#import "CCNode+NodeInfo.h"
#import "PlugInNode.h"
#import "CocosBuilderAppDelegate.h"
#import "SequencerSequence.h"
#include "SequencerScrubberSelectionView.h"

static SequencerHandlerTimeline *sharedSequencerHandlerTimeline = nil;

@implementation SequencerHandlerTimeline

@synthesize dragAndDropEnabled;
@synthesize outlineTimeline;
@synthesize scroller;
@synthesize currentSequence;
@synthesize scrubberSelectionView;

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
    
//    [outlineTimeline setDataSource:self];
//    [outlineTimeline setDelegate:self];
//    [outlineTimeline reloadData];
    
    return self;
}

- (void) redrawTimeline:(BOOL) reload
{
    [scrubberSelectionView setNeedsDisplay:YES];
    [self updateScroller];
    if (reload) {
//        [outlineTimeline reloadData];
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
        
//        [outlineTimeline reloadData];
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

#pragma mark Handle scroller

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

#pragma mark Destructor

- (void) dealloc
{
    self.currentSequence = nil;
    self.scrubberSelectionView = nil;
    
    [super dealloc];
}

@end
