//
//  CardGameViewController.h
//  Matchima
//
//  Created by Mukhtar Yusuf on 1/28/17.
//  Copyright © 2017 Mukhtar Yusuf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "CardMatchingGame.h"
#import "Deck.h"
#import "PlayingCard.h"
#import "SetCard.h"
#import "Grid.h"
#import "MyGrid.h"
#import "PlayingCardView.h"
#import "SetCardView.h"
#import "HighScore+CoreDataProperties.h"

@interface CardGameViewController : UIViewController
@property (strong, nonatomic) IBOutletCollection(UIView) NSMutableArray *cardViews;
@property (weak, nonatomic) IBOutlet UIView *cardContainerView;
@property (strong, nonatomic) Grid *gridForCards; //Protected for subclasses
@property (strong, nonatomic) MyGrid *myGridForCards; //Protected for subclasses
@property (strong, nonatomic) NSMutableArray *cardViewFrames; //Protected for subclasses
@property (strong, nonatomic) UIManagedDocument *document;
@end
