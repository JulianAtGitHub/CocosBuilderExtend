//
//  SequencerHandlerTimeline.h
//  CocosBuilder
//
//  Created by wei.zhu on 12/3/13.
//
//

#import <Foundation/Foundation.h>

@class CocosBuilderAppDelegate;
@class SequencerSequence;
@class SequencerScrubberSelectionView;
@class SequencerKeyframe;

@interface SequencerHandlerTimeline : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate> {
    
    CocosBuilderAppDelegate *appDelegate;
    
    NSOutlineView *outlineTimeline;
    NSScroller *scroller;
    
    SequencerSequence *currentSequence;
    SequencerScrubberSelectionView *scrubberSelectionView;
    SequencerKeyframe* contextKeyframe;
    
    NSTextField *keyframeEasingType;
    NSSlider *keyframeEasingSlide;
    NSView *keyframeEasingDetailView;
}

@property (nonatomic,assign) BOOL dragAndDropEnabled;

@property (nonatomic,readonly) NSOutlineView *outlineTimeline;
@property (nonatomic,retain) NSScroller *scroller;

@property (nonatomic,retain) SequencerSequence *currentSequence;
@property (nonatomic,retain) SequencerScrubberSelectionView *scrubberSelectionView;
@property (nonatomic,retain) SequencerKeyframe* contextKeyframe;

@property (nonatomic,retain) NSTextField *keyframeEasingType;
@property (nonatomic,retain) NSSlider *keyframeEasingSlide;
@property (nonatomic,retain) NSView *keyframeEasingDetailView;

+ (SequencerHandlerTimeline *) sharedHandlerTimeline;

- (instancetype) initWithOutlineView:(NSOutlineView *)view;

- (void) toggleSeqExpanderForRow:(int)row;

- (void) redrawTimeline:(BOOL) reload;
- (void) redrawTimeline;
- (void) updateScroller;
- (void) updateScrollerToShowCurrentTime;

- (float) visibleTimeArea;
- (float) maxTimelineOffset;

- (void) updatePropertiesToTimelinePosition;

- (void) refreshKeyframeEasingDetail;

@end
