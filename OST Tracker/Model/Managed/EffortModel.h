#import "_EffortModel.h"

@interface EffortModel : _EffortModel
// Custom logic goes here.
@property (assign, nonatomic) BOOL bulkSelected;
- (BOOL) checkIfEffortShouldBeInSplit:(NSString*)split;

@end
