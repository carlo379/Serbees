//  SearchViewController.h
//  SerBees

#import <UIKit/UIKit.h>

// Protocol to notify when the "...search" button was pressed or when a user made a selection
@protocol SearchViewControllerDelegate <NSObject>
- (void)searchPanelClosed;
- (void)searchPressedwithTags:(NSString *)tags andSections:(NSArray *)sectionsArray andRange:(NSInteger)range;
@end

@interface SearchViewController : UIViewController

// delegate property for protocol set-up.
@property (nonatomic, weak) id <SearchViewControllerDelegate> delegate;

@end
