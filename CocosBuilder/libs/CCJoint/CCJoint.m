//
//  CCJoint.m
//  CocosBuilder
//
//  Created by wei.zhu on 12/5/13.
//
//

#import "CCJoint.h"
#import "CCDrawNode.h"
#import "CCGrid.h"
#import "kazmath/kazmath.h"

// externals
#import "kazmath/GL/matrix.h"

@implementation CCJoint

@synthesize fillColor = _fillColor;
@synthesize length = _length;

#pragma mark CCNode - Init & cleanup

+(id) node
{
	return [[[self alloc] init] autorelease];
}

-(id) init
{
	if ((self=[super init]) ) {
        _indicator = [[CCDrawNode alloc] init];
        _indicator.anchorPoint = CGPointMake(0.0, 0.0); // this is optional
        _fillColor = ccGRAY;
        _length = 1.0f;
        
        [self setupIndicatorPolygon];
        [self setupIndicatorScale];
	}
    
	return self;
}

- (void) setupIndicatorPolygon
{
    CGPoint vertices[4] = { {0.0f, 0.0f}, {-20.0f, 40.0f}, {0.0f, 500.0f}, {20.0f, 40.0f}};
    [_indicator drawPolyWithVerts:vertices count:4 fillColor:ccc4FFromccc3B(_fillColor) borderWidth:0.0f borderColor:ccc4FFromccc3B(_fillColor)];
}

- (void) setupIndicatorScale
{
    float scaleY = _length * 0.1f;
    float scaleX = _length * 0.09f;
    [_indicator setScaleX:scaleX];
    [_indicator setScaleY:scaleY];
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
    [self setupIndicatorScale];
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
