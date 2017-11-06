//
//  CardMatchingGame.m
//  Matchismo
//
//  Created by Mukhtar Yusuf on 7/30/14.
//  Copyright (c) 2014 Mukhtar Yusuf. All rights reserved.
//

#import "CardMatchingGame.h"
#import "SetCard.h"

@interface CardMatchingGame()
@property (strong, nonatomic) Deck *deck;
@property (strong, nonatomic) Deck *permanentDeck;

@end

@implementation CardMatchingGame

static int MISMATCH_PENALTY = 1; //Was 2
static const int MATCH_BONUS = 10; //Was 4
static int COST_TO_CHOOSE = 1;
static const float MISMATCH_PEN_RATIO_DENOMINATOR = 100.0;
static const float CTC_RATIO_DENOMINATOR = 100.0;
static const int MAXIMUM_MISMATCH_PEN = 2;
static const int MAXIMUM_CTC = 2;

static const int START_TOTAL_TIME = 10;
static const int SUB_TIME = 10;
static int MATCH_TIME_BONUS = 4;

static const int MULTIPLIER_PROBABILITY_DENOMINATOR = 3; // 1/3

NSMutableArray *chosenCards;

- (void)setIsMultiplierActive:(BOOL)isMultiplierActive{
    if(isMultiplierActive == NO)
        self.multiplier = 1;
    
    _isMultiplierActive = isMultiplierActive;
}

- (NSMutableArray *)cards{
    if(!_cards) _cards = [[NSMutableArray alloc] init];
    return _cards;
}

@synthesize multiplier = _multiplier;

- (NSUInteger)multiplier{
    if(_multiplier == 0)
        _multiplier = 1;
    
    return _multiplier;
}

- (void)setmultiplier:(NSUInteger)multiplier{
    if(multiplier == 0)
        _multiplier = 1;
    else
        _multiplier = multiplier;
}

//Designated Initializer
- (instancetype)initWithCardCount:(NSUInteger)count usingDeck:(Deck *)deck{
    self = [super init];
    BOOL isGameValid = NO;
    if(self){
        self.permanentDeck = deck;
        self.cardCount = count;
        isGameValid = [self populateGameWithCount:count];
        self.totalTime = START_TOTAL_TIME;
        self.subTime = SUB_TIME;
    }
    if(isGameValid)
        return self;
    else
        return nil;
}

//Return card at index
- (Card *)cardAtIndex:(NSUInteger)index{
    return (index < [self.cards count]) ? self.cards[index] : nil;
}

-(Card *)drawOneCardIntoGame{
    Card *card = [self.deck drawRandomCard];
    if(card)
        [self.cards addObject:card];
    return card;
}

-(NSMutableArray *)drawThreeCardsIntoGame{
    NSMutableArray *drawnCards; //Of Card
    if([self.deck cardCount] >= 3){
        for(int i = 1; i <= 3; i++){
            Card *drawnCard = [self drawOneCardIntoGame];
            if(drawnCard)
                [drawnCards addObject:drawnCard];
        }
    }
    return drawnCards;
}

//Select card at index and perform operations
- (void)chooseCardAtIndex:(NSUInteger)index{
    self.isGameActive = YES;
    if(!self.timer){
        self.timer = [NSTimer timerWithTimeInterval:1.0f
                                             target:self
                                           selector:@selector(updateTime)
                                           userInfo:nil
                                            repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        self.startGameDate = [NSDate date];
    }
    
    if(!chosenCards){
        chosenCards = [[NSMutableArray alloc] init];
    }
    
    Card *card = [self cardAtIndex:index];
    if([card isKindOfClass:[SetCard class]]){
        self.threeCardGame = YES;
    }
    
    int matchScore = 0;
    NSUInteger chosenCardCount = 0;
    
    if(!card.isMatched){
        if(card.isChosen){
            card.chosen = NO;
        }
        else{ // Put Cards that are chosen but not matched in an array
            for(Card *otherCard in self.cards){
                if(otherCard.isChosen && !otherCard.isMatched && ![chosenCards containsObject:otherCard]){
                    [chosenCards addObject:otherCard];
                }
            }
            
            matchScore = [card match:chosenCards];
            chosenCardCount = [chosenCards count];
    
            
            if(!self.threeCardGame && [chosenCards count] == 1){//Matching for a two card game
                if(matchScore){
                    [self updateGameForMatch:card forScore:matchScore];
                }
                else{
                    [self updateGameForMismatch:card];
                }
            }
            else if([chosenCards count] == 2 && self.threeCardGame){//Matching for a three card game
                if(matchScore){
                    [self updateGameForMatch:card forScore:matchScore];
                }
                else{
                    [self updateGameForMismatch:card];
                }
            }
//            if(card == nil)
//                NSLog(@"In card not matched else for update");
            if(self.score >= 200){
                COST_TO_CHOOSE = floor(self.score/CTC_RATIO_DENOMINATOR);
                if(COST_TO_CHOOSE > MAXIMUM_CTC)
                    COST_TO_CHOOSE = MAXIMUM_CTC;
            }
            else
                COST_TO_CHOOSE = 1;
            self.score -= COST_TO_CHOOSE;
            card.chosen = YES;
        }
    }
}

//--Helper Methods--
#pragma mark Helper Methods

//Update score for match
-(void)updateGameForMatch:(Card *)chosenCard forScore:(int)score{
    if(self.totalTime >= 25){
        if(self.totalTime >= 30)
            MATCH_TIME_BONUS = 1;
        MATCH_TIME_BONUS = 2;
    }
    else
        MATCH_TIME_BONUS = 4;
    self.score += score * MATCH_BONUS * self.multiplier;
    self.totalTime += MATCH_TIME_BONUS;
    chosenCard.matched = YES;
    
    for(Card *otherCard in chosenCards){
        otherCard.matched = YES;
    }

    [chosenCards removeAllObjects];
    
    if(self.isMultiplierActive)
        self.multiplier++;
}

//Update score for mismatch
-(void)updateGameForMismatch:(Card *)chosenCard{
    if(self.score >= 100){
        MISMATCH_PENALTY = ceil(self.score/MISMATCH_PEN_RATIO_DENOMINATOR);
        if(MISMATCH_PENALTY > MAXIMUM_MISMATCH_PEN)
            MISMATCH_PENALTY = MAXIMUM_MISMATCH_PEN;
    }else{
        MISMATCH_PENALTY = 1;
    }
    self.multiplier = 1;
    self.score -= MISMATCH_PENALTY;
    
    for(Card *otherCard in chosenCards){
        otherCard.chosen = NO;
    }
    [chosenCards removeAllObjects];
}

//Update Time
-(void)updateTime{
//    NSLog(@"In Update Time");
    
    if(self.totalTime > 0){//Game Hasn't Ended
        self.totalPlayTime++;
        self.totalTime--;
        if(self.subTime > 1)
            self.subTime--;
        else{//Reset Time and Shuffle Cards
            if(self.totalTime > SUB_TIME)
                self.subTime = SUB_TIME;
            else
                self.subTime = self.totalTime;
            [self populateGameWithCount:self.cardCount];
            int randomMultiplierProbabilityValue = arc4random_uniform(MULTIPLIER_PROBABILITY_DENOMINATOR);
            if(randomMultiplierProbabilityValue == 0)
                self.isMultiplierActive = YES;
            else
                self.isMultiplierActive = NO;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:RESET_CARDS_NOTIFICATION object:nil];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_TIME_NOTIFICATION object:nil];
    }
    if(self.totalTime == 0){//Game Has Ended
        
        //Update Flags Here or Something
        [self.timer invalidate];
        self.isGameActive = NO;
        self.hasGameEnded = YES;
        self.endGameDate = [NSDate dateWithTimeInterval:self.totalPlayTime sinceDate:self.startGameDate];
        [[NSNotificationCenter defaultCenter] postNotificationName:GAME_ENDED_NOTIFICATION object:nil];
    }
}

-(BOOL)populateGameWithCount:(NSUInteger)count{
    id someId = [self.permanentDeck copy];
    if([someId isKindOfClass:[Deck class]])
        self.deck = (Deck *)someId;
    
    if([self.cards count] != 0){
        [self.cards removeAllObjects];
    }

    for(int i = 0; i < count; i++){
        Card *randomCard = [self.deck drawRandomCard];
        if(randomCard){
            [self.cards insertObject:randomCard atIndex:[self.cards count]];
        }
        else{
            return false;
        }
    }

    return true;
}

@end
