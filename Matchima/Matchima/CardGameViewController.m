//
//  CardGameViewController.m
//  Matchima
//
//  Created by Mukhtar Yusuf on 1/28/17.
//  Copyright © 2017 Mukhtar Yusuf. All rights reserved.
//

#import "CardGameViewController.h"

@interface  CardGameViewController()
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *subTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UILabel *pausedLabel;

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UIView *menu;


@property (strong, nonatomic) CardMatchingGame *game;
@property (strong, nonatomic) UIDynamicAnimator *animator;
@property (strong, nonatomic) UIAttachmentBehavior *attachTopBehavior;
@property (nonatomic) BOOL areCardsInPile;

@end

@implementation CardGameViewController

CGFloat originalAnchorLength;
CGRect originalCardContainerBounds;

static const int INITIAL_NUMBER_OF_CARDS = 12;
static const double CARD_ASPECT_RATIO = 0.5;

static int NUMBER_OF_COLUMNS = 4;
static int NUMBER_OF_ROWS = 3;

- (IBAction)pause:(id)sender {
    if(self.isGamePaused)
        [self resumeGame];
    else
        [self pauseGame];
}

- (IBAction)dealAgain:(UIButton *)sender{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Deal Again?"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *dealAction = [UIAlertAction actionWithTitle:@"Deal Again"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           [self dealAgainConfirm];
                                                       }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             //Do Nothing
                                                         }];
    [alert addAction:dealAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}

- (IBAction)drawThreeCards:(id)sender{
    [self drawThree];
}

-(void)tapRootView:(UITapGestureRecognizer *)sender{
    NSLog(@"In tap gesture recognizer");
    NSLog(@"Are cards in pile in tap: %@", self.areCardsInPile ? @"Yes":@"No");
    if(self.areCardsInPile){
        NSLog(@"In tap gesture recognizer 2");
        self.areCardsInPile = !self.areCardsInPile;
        [self animateCardsToOriginalLocations];
    }
}

-(void)panRootView:(UIPanGestureRecognizer *)sender{
    if(self.areCardsInPile){
        NSLog(@"In Pan");
        UIView *topCard = [self.cardViews lastObject];
        if(sender.state == UIGestureRecognizerStateBegan){
            _attachTopBehavior = [[UIAttachmentBehavior alloc] initWithItem:topCard attachedToAnchor:[sender locationInView:self.view]];
            _attachTopBehavior.length = 0.0;
            [self.animator addBehavior:_attachTopBehavior];
        }else if(sender.state == UIGestureRecognizerStateChanged){
            [_attachTopBehavior setAnchorPoint:[sender locationInView:self.view]];
        }else if(sender.state == UIGestureRecognizerStateEnded){
            [self.animator removeBehavior:_attachTopBehavior];
        }
    }
}

-(void)pinchContainer:(UIPinchGestureRecognizer *)sender{
    UIView *topView = [self.cardViews lastObject];
    NSLog(@"Are cards in pile: %@", self.areCardsInPile ? @"YES":@"NO");
    if(!self.areCardsInPile){
        if(sender.state == UIGestureRecognizerStateBegan){
            for(UIView *cardView in self.cardViews){
                [UIView animateWithDuration:1.0
                                 animations:^{
                                     CGFloat halfWidth = self.cardContainerView.bounds.size.width/2;
                                     CGFloat halfHeight = self.cardContainerView.bounds.size.height/2;
                                     CGPoint containerCenter = CGPointMake(halfWidth, halfHeight);
                                     cardView.center = containerCenter;
                                 }
                                 completion:^(BOOL finished){
                                     if (finished) {
                                         if(cardView != topView){
                                             UIAttachmentBehavior *attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:cardView attachedToItem:topView];
                                             [self.animator addBehavior:attachmentBehavior];
                                         }else if (cardView == topView)
                                             self.areCardsInPile = !self.areCardsInPile;
                                     }
                                 }
                 ];
            }
        }
//        self.areCardsInPile = !self.areCardsInPile;
    }
}

-(void)tapCard:(UITapGestureRecognizer *)sender{
    
    self.pauseButton.enabled = YES;
    NSUInteger chosenCardIndex = [self.cardViews indexOfObject:sender.view];
    NSLog(@"In tapCard: %lu", chosenCardIndex);
//    Card *card = [self.game cardAtIndex:chosenCardIndex];
//    
//    NSLog(@"Is this tapped chosen: %@", card.isChosen ? @"YES":@"NO");
    [self.game chooseCardAtIndex:chosenCardIndex];
    [self updateUI];
}

-(void)drawThree{
    NUMBER_OF_COLUMNS++;
    [self setUpContainerViewHeight];
    [self setUpMyGrid];
    __block int cardIndex = 0;
    for(int i = 0; i < self.myGridForCards.numOfRows; i++){
        for(int j = 0; j < self.myGridForCards.numOfColumns; j++){
            if(j != self.myGridForCards.numOfColumns-1){
                [UIView animateWithDuration:0.4
                                 animations:^{
                                     ((UIView *)self.cardViews[cardIndex]).frame = [self.myGridForCards frameForCellInRow:i andColumn:j]; //Use Introspection?
                                 }];
                cardIndex++;
                 
            }else{
                SetCard *drawnSetCard = (SetCard *)[self.game drawOneCardIntoGame]; //Use Introspection?
                CGRect initialFrame;
                initialFrame.origin = CGPointMake(self.myGridForCards.size.width-[self.myGridForCards cellWidth], 0.0);
                SetCardView *newScv = [[SetCardView alloc] initWithFrame:initialFrame];
                if(drawnSetCard){
                    newScv.shape = drawnSetCard.shape;
                    newScv.color = drawnSetCard.color;
                    newScv.number = drawnSetCard.number;
                    newScv.shading = drawnSetCard.shading;
                    newScv.isChosen = drawnSetCard.isChosen;
                    
                    [self.cardContainerView addSubview:newScv];
                    [self.cardViews insertObject:newScv atIndex:cardIndex];
                    [UIView animateWithDuration:0.4
                                     animations:^{
                                         newScv.frame = [self.myGridForCards frameForCellInRow:i andColumn:j];
                                         [self.cardViewFrames insertObject:[NSValue valueWithCGRect:newScv.frame] atIndex:cardIndex];
                                         cardIndex++;
                                     }];
                }
            }
        }
    }
}

-(void)updateUI{
//    NSLog(@"UpdateUI Called");
    NSMutableArray *addedCards = [[NSMutableArray alloc] initWithCapacity:3];
    for(UIView *cardView in self.cardViews){
        NSUInteger cardIndex = [self.cardViews indexOfObject:cardView];
        Card *card = [self.game cardAtIndex:cardIndex];
        if([card isKindOfClass:[PlayingCard class]]){
//            NSLog(@"UpdateUI Called and card is playing card");
            if([cardView isKindOfClass:[PlayingCardView class]]){
                PlayingCardView *playingCardView = (PlayingCardView *)cardView;
                PlayingCard *playingCard = (PlayingCard *)card;
//                NSLog(@"Is this chosen: %@", card.isChosen ? @"YES":@"NO");
                playingCardView.rank = playingCard.rank;
                playingCardView.suit = playingCard.suit;
                playingCardView.isMatched = playingCard.isMatched;
                if(card.isChosen != playingCardView.faceUP){
                    [UIView transitionWithView:playingCardView
                                  duration:0.4
                                   options:UIViewAnimationOptionTransitionFlipFromLeft
                                    animations:nil
                                completion:nil];
                }
                playingCardView.faceUP = playingCard.isChosen;
            }
        }else if([card isKindOfClass:[SetCard class]]){
            if([cardView isKindOfClass:[SetCardView class]]){
                SetCardView *setCardView = (SetCardView *)cardView;
                SetCard *setCard = (SetCard *)card;
                setCardView.shape = setCard.shape;
                setCardView.color = setCard.color;
                setCardView.number = setCard.number;
                setCardView.shading = setCard.shading;
                setCardView.isChosen = setCard.isChosen;
                if(setCard.isMatched && setCardView.alpha != 0.0){
                    setCardView.alpha = 0.0;
                    CGRect rectForMatchedCard = setCardView.frame;
                    CGFloat initialXValue = arc4random_uniform(self.cardContainerView.bounds.size.width);
                    CGRect initialFrame;
                    initialFrame.origin = CGPointMake(initialXValue, 0);
                    initialFrame.size = rectForMatchedCard.size;
                    
                    SetCard *drawnCard = (SetCard *)[self.game drawOneCardIntoGame];//Use Introspection?
                    SetCardView *newScv = [[SetCardView alloc] initWithFrame:initialFrame];
                    newScv.shape = drawnCard.shape;
                    newScv.color = drawnCard.color;
                    newScv.number = drawnCard.number;
                    newScv.shading = drawnCard.shading;
                    newScv.isChosen = drawnCard.isChosen;
                    [self.cardContainerView addSubview:newScv];
                    [addedCards addObject:newScv];
                    [newScv addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCard:)]];
                    
                    [UIView animateWithDuration:1.0
                                     animations:^{
                                         newScv.frame = rectForMatchedCard;
                                         [self.cardViewFrames addObject:[NSValue valueWithCGRect:newScv.frame]];
                                     }];
                }
            }
        }
    }
    [self.cardViews addObjectsFromArray:addedCards];
//    NSLog(@"Number of cards in outlet: %lu", [self.cardViews count]);
//    NSLog(@"Number of cards in added cards: %lu", [addedCards count]);
    self.scoreLabel.text = [NSString stringWithFormat:@"Score: %li", self.game.score];
    
    [self updateTimeLabels];
}

-(void)updateTimeLabels{
    self.totalTimeLabel.text = [NSString stringWithFormat:@"Time Left: %li", self.game.totalTime];
    self.subTimeLabel.text = [NSString stringWithFormat:@"Reset Time: %li", self.game.subTime];
}

-(void)animateCardsToOriginalLocations{
    for(int i = 0; i < [self.cardViews count]; i++){
        [UIView animateWithDuration:0.3
                         animations:^{
                            ((UIView *)self.cardViews[i]).frame = ((NSValue *)self.cardViewFrames[i]).CGRectValue;
                         }];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if([keyPath isEqualToString:@"subTime"]){
        [self updateTimeLabels];
        if(self.game.totalTime == 0){//Game has ended
            [self processEndOfGame];
        }
    }
    
#warning Remove KVO for cards
    
    if([keyPath isEqualToString:@"cards.@count"]){
        NSLog(@"In cards change kvo");
        NUMBER_OF_COLUMNS = 4;
        NUMBER_OF_ROWS = 3;
        self.cardContainerView.bounds = originalCardContainerBounds;
        [self setUpContainerViewHeight];
        [self setUpMyGrid];
        [self removeAllCardSubViews];
        [self initializeAndAddCardViews];
        [self addTapGestureRecognizerToCards];
        [self updateUI];
    }
}


//--Getters and Setters--
#pragma mark - Getters and Setters
- (NSUserDefaults *)userDefaults{
    if(!_userDefaults)
        _userDefaults = [NSUserDefaults standardUserDefaults];
    
    return _userDefaults;
}

- (NSDictionary *)settings{
    if(!_settings)
        _settings = [self.userDefaults objectForKey:SETTINGS];
    
    return _settings;
}

-(Grid *)gridForCards{
    if(!_gridForCards)
        _gridForCards = [[Grid alloc] init];
    return _gridForCards;
}

-(MyGrid *)myGridForCards{
    if(!_myGridForCards)
        _myGridForCards = [[MyGrid alloc] init];
    return _myGridForCards;
}

@synthesize game = _game;

-(CardMatchingGame *)game{
    if(!_game)
        _game = [self createGame];
    _game.threeCardGame = NO;
    return _game;
}

#warning Consider removing method
-(void)setGame:(CardMatchingGame *)game{
    _game = game;
}

-(NSMutableArray *)cardViews{
    if(!_cardViews)
        _cardViews = [[NSMutableArray alloc] init];
    return _cardViews;
}
-(UIDynamicAnimator *)animator{
    if(!_animator)
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.cardContainerView];
    return _animator;
}
-(NSMutableArray *)cardViewFrames{
    if(!_cardViewFrames)
        _cardViewFrames = [[NSMutableArray alloc] init];
    return _cardViewFrames;
}
-(NSUInteger)numOfRows{
    return 0;
}

//--Setup Code--
#pragma mark - Setup

- (void)setUpBackgroundImage{
    if([self.settings objectForKey:HAS_BACKGROUND_IMAGE]){
        self.backgroundImage.hidden = NO;
        [self.backgroundImage setImage:[UIImage imageNamed:[self.settings objectForKey:BACKGROUND_IMAGE]]];
    }else{
        self.backgroundImage.hidden = YES;
    }
}

- (void)setUpMenuColor{
    NSDictionary *menuColor = [self.settings objectForKey:MENU_COLOR];
    
    float red = [[menuColor objectForKey:RED] floatValue] / 255;
    float green = [[menuColor objectForKey:GREEN] floatValue] / 255;
    float blue = [[menuColor objectForKey:BLUE] floatValue] / 255;
    double alpha = [[menuColor objectForKey:ALPHA] doubleValue];
    
    self.menu.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

-(void)hideNavBar{
    [self.navigationController setNavigationBarHidden:YES];
}

-(void)setUpMyGrid{
    self.myGridForCards.size = self.cardContainerView.bounds.size;
    self.myGridForCards.numOfColumns = NUMBER_OF_COLUMNS;
    self.myGridForCards.numOfRows = NUMBER_OF_ROWS;
}

-(void)setUpGrid{
    self.gridForCards.size = self.cardContainerView.bounds.size;
    self.gridForCards.minimumNumberOfCells = INITIAL_NUMBER_OF_CARDS;
    self.gridForCards.cellAspectRatio = CARD_ASPECT_RATIO;
}

//Implemented in subclasses
-(void)initializeAndAddCardViews{
}
                 
//Implemented in subclasses
-(Deck *)createDeck{
    return nil;
}

-(CardMatchingGame *)createGame{
    NSLog(@"Card count when creating game: %li", self.cardViews.count);
    return [[CardMatchingGame alloc] initWithCardCount:[self.cardViews count] usingDeck:[self createDeck]];
}

-(void)addObserverForCards{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUI)
                                                 name:@"reset"
                                               object:nil];
}

-(void)addKVOForCards{
    [self.game addObserver:self
                forKeyPath:@"cards.@count"
                   options:NSKeyValueObservingOptionNew
                   context:nil];
}

-(void)removeKVOForCards{
    [self.game removeObserver:self
                   forKeyPath:@"cards.@count"];
}

-(void)addKVOForGameTimers{
    [self.game addObserver:self
                forKeyPath:@"subTime"
                   options:NSKeyValueObservingOptionNew
                   context:nil];
}

-(void)removeKVOForGameTimers{
    [self.game removeObserver:self
                   forKeyPath:@"subTime"];
}

-(void)addTapGestureRecognizerToCards{
    for(UIView *cardView in self.cardViews){
        [cardView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCard:)]];
    }
}

-(void)addPinchRecognizerToCardContainer{
    [self.cardContainerView addGestureRecognizer:[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchContainer:)]];
}

-(void)addPanRecognizerToRootView{
    [self.view addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panRootView:)]];
}

-(void)addTapRecognizerToRootView{
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRootView:)]];
}

-(void)setUpContainerViewHeight{
    CGFloat deductFromHeight = self.cardContainerView.bounds.size.height - [self deductFromHeightFactor]*[self deductFromHeightCoeff];
    [self.cardContainerView setBounds:CGRectMake(self.cardContainerView.bounds.origin.x, self.cardContainerView.bounds.origin.y, self.cardContainerView.bounds.size.width, deductFromHeight)];
}

-(int)deductFromHeightFactor{
    return NUMBER_OF_COLUMNS - (NUMBER_OF_ROWS + 1);
}

-(CGFloat)deductFromHeightCoeff{
    return self.cardContainerView.bounds.size.height/7;
}

-(void)removeAllCardSubViews{
    for(UIView *view in self.cardContainerView.subviews){
        [view removeFromSuperview];
    }
}

//--Core Data Setup Code--
#pragma mark Core Data Setup Code
-(void)createAndOpenManagedDocument{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentsDirectory = [[fileManager URLsForDirectory:NSDocumentDirectory
                                                     inDomains:NSUserDomainMask] firstObject];
    NSString *documentName = @"MatchimaDB";
    NSURL *url = [documentsDirectory URLByAppendingPathComponent:documentName];
    self.document = [[UIManagedDocument alloc] initWithFileURL:url];
    
    BOOL fileExists = [fileManager fileExistsAtPath:[url path]];
    if(fileExists){
        [self.document openWithCompletionHandler:^(BOOL success){
            //Display contents of DB
            [self displayDBContents];
        }];
    }else{
        [self.document saveToURL:url
                forSaveOperation:UIDocumentSaveForCreating
               completionHandler:^(BOOL success) {
                   //Populate Database for the first time
                   [self insertDefaultValuesIntoDB];
                   [self displayDBContents];
               }];
    }
}

//--Helper Methods--
#pragma mark Helper Methods

- (void)settingsUpdated{
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    self.settings = [self.userDefaults objectForKey:SETTINGS];
    NSLog(@"In settings updated %@", self.settings);
    [self setUpBackgroundImage];
    [self setUpMenuColor];
    [self setCardBackImages];
}

//Implemented in subclass
- (void)setCardBackImages{
}

#warning Consider setup method for dealAgainConfirm and viewDidLoad
-(void)dealAgainConfirm{
    self.pausedLabel.hidden = YES;
    self.cardContainerView.hidden = NO;
    self.pauseButton.enabled = NO;
    self.isGamePaused = NO;
    [self removeKVOForGameTimers];
    [self removeKVOForCards];
    NUMBER_OF_COLUMNS = 4;
    NUMBER_OF_ROWS = 3;
    self.cardContainerView.bounds = originalCardContainerBounds;
    [self setUpContainerViewHeight];
    [self setUpMyGrid];
    self.game = [self createGame];
    [self addKVOForGameTimers];
    [self addKVOForCards];
    [self removeAllCardSubViews];
    [self initializeAndAddCardViews];
    [self addTapGestureRecognizerToCards];
    [self updateUI];
}

-(void)pauseGame{
    if(self.pauseButton.isEnabled){//Only Pause if the game's started
        if(!self.isGamePaused){
            [self.game.timer invalidate];
            
            self.cardContainerView.hidden = YES;
            self.pausedLabel.hidden = NO;
            self.isGamePaused = YES;
        }
    }
    
//    UIAlertController *pauseAlert = [UIAlertController alertControllerWithTitle:@"Game Paused"
//                                                                        message:nil preferredStyle:UIAlertControllerStyleAlert];
//    
//    UIAlertAction *unPauseAction = [UIAlertAction actionWithTitle:@"Resume"
//                                                            style:UIAlertActionStyleCancel
//                                                          handler:^(UIAlertAction * _Nonnull action) {
//                                                              [self resumeGame];
//                                                          }];
//    [pauseAlert addAction:unPauseAction];
//    [self presentViewController:pauseAlert
//                       animated:YES
//                     completion:nil];
}

-(void)resumeGame{
    if(self.isGamePaused){
        self.cardContainerView.hidden = NO;
        self.pausedLabel.hidden = YES;
        self.game.timer = [NSTimer timerWithTimeInterval:1.0f
                                             target:self.game
                                           selector:@selector(updateTime)
                                           userInfo:nil
                                            repeats:YES];
        
        [[NSRunLoop currentRunLoop] addTimer:self.game.timer forMode:NSRunLoopCommonModes];;
        self.isGamePaused = NO;
    }
}

-(void)insertDefaultValuesIntoDB{
    NSArray *ranks = @[@1, @2, @3, @4, @5];
    NSArray *names = @[@"Matchima_Master", @"Matchima_Pro", @"ProGamer", @"Dude", @"Legend"];
    NSArray *scores = @[@100, @90, @80, @70, @60];
    
    for(int i = 0; i < [ranks count]; i++){
        [HighScore insertHighScoreWithRank:[(NSNumber *)ranks[i] intValue]
                                      name:names[i]
                                     value:[(NSNumber *)scores[i] intValue]
                                andContext:self.document.managedObjectContext];
    }
}

-(void)displayDBContents{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"HighScore"];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"rank"
                                                                     ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    
    NSArray *highScores = [[NSArray alloc] init];
    
    highScores = [self.document.managedObjectContext executeFetchRequest:fetchRequest
                                                                       error:nil];
    
    for(HighScore *highScore in highScores){
        NSLog(@"Rank: %i   Name: %@  Score: %i", highScore.rank, highScore.name, highScore.value);
    }
}

//--Creation Method for Core Data--
//+ (void)insertHighScoreWithRank:(int)rank name:(NSString *)name value:(int)value andContext:(nonnull NSManagedObjectContext *)context{
//    HighScore *highScore = [NSEntityDescription insertNewObjectForEntityForName:@"HighScore" inManagedObjectContext:context];
//    
//    highScore.rank = rank;
//    highScore.name = name;
//    highScore.value = value;
//}


//--View Controller Life Cycle--
#pragma mark - View Controller Lifecycle
-(void)viewDidLoad{
    [super viewDidLoad];
    originalCardContainerBounds = self.cardContainerView.bounds;
    [self setUpContainerViewHeight];
    [self setUpMyGrid];
//    [self setUpGrid];
    [self initializeAndAddCardViews];
    [self addTapGestureRecognizerToCards];
    [self addPinchRecognizerToCardContainer];
    [self addPanRecognizerToRootView];
    [self addTapRecognizerToRootView];
    [self addKVOForGameTimers];
    [self addKVOForCards];
    [self addObserverForCards];
    [self updateUI];
    [self createAndOpenManagedDocument];
    NSLog(@"Card outlet count: %lu", (unsigned long)[self.cardViews count]);
}

@end
