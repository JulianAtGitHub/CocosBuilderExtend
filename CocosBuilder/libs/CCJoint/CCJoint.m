//
//  CCJoint.m
//  CocosBuilder
//
//  Created by wei.zhu on 12/5/13.
//
//

#import "CCJoint.h"
#import "CCSprite.h"
#import "CCGrid.h"
#import "kazmath/kazmath.h"

// externals
#import "kazmath/GL/matrix.h"

@implementation CCJoint

@synthesize length = _length;

#pragma mark CCNode - Init & cleanup

+(id) node
{
	return [[[self alloc] init] autorelease];
}

-(id) init
{
	if ((self=[super init]) ) {
        _indicator = [[CCSprite alloc] initWithFile:@"joint-arrow.png"];
        _indicator.rotation = -90.0f;
        _indicator.anchorPoint = CGPointMake(0.0, 0.5); // this is optional
        self.length = 0.75;

	}
    
	return self;
}

- (void) dealloc
{
	CCLOGINFO( @"cocos2d: deallocing %@", self);
    
    [_indicator release];
    
	[super dealloc];
}

#pragma mark property

- (void) setLength:(float)length
{
    _length = length;
    [_indicator setScale:_length];
}

- (BOOL) indicatorVisible
{
    return _indicator.visible;
}

- (void) setIndicatorVisible:(BOOL)indicatorVisible
{
    _indicator.visible = indicatorVisible;
}

#pragma mark joint visit

-(void) visit
{
	// quick return if not visible. children won't be drawn.
	if (!_visible)
		return;
    
	kmGLPushMatrix();
    
	if ( _grid && _grid.active)
		[_grid beforeDraw];
    
	[self transform];
    
	if(_children) {
        
		[self sortAllChildren];
        
		ccArray *arrayData = _children->data;
		NSUInteger i = 0;
        
		// draw children zOrder < 0
		for( ; i < arrayData->num; i++ ) {
			CCNode *child = arrayData->arr[i];
			if ( [child zOrder] < 0 )
				[child visit];
			else
				break;
		}
        
		// self draw
		[self draw];
        
		// draw children zOrder >= 0
		for( ; i < arrayData->num; i++ ) {
			CCNode *child =  arrayData->arr[i];
			[child visit];
		}
        
	} else {
		[self draw];
    }
    
    [_indicator visit];
    
	// reset for next frame
	_orderOfArrival = 0;
    
	if ( _grid && _grid.active)
		[_grid afterDraw:self];
    
	kmGLPopMatrix();
}

@end
