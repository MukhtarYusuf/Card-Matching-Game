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
@property (nonatomic, readwrite) NSInteger score;
@property (strong, nonatomic, readwrite) NSMutableArray *cards;//of Card
@property (strong, nonatomic) Deck *deck;
@property (strong, nonatomic) Deck *permanentDeck;

@end

@implementation CardMatchingGame

static const int MISMATCH_PENALTY = 2;
static const int MATCH_BONUS = 4;
static const int COST_TO_CHOOSE = 1;

static const int START_TOTAL_TIME = 3;
static const int SUB_TIME = 3;
static const int MATCH_TIME_BONUS = 8;

NSMutableArray *chosenCards;

- (NSMutableArray *)cards{
    if(!_cards) _cards = [[NSMutableArray alloc] init];
    return _cards;
}

//Bla Bla

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
    NSLog(@"In chooseCardAtIndex: %lu", index);
    if(!self.timer){
        self.timer = [NSTimer timerWithTimeInterval:1.0f
                                             target:self
                                           selector:@selector(updateTime)
                                           userInfo:nil
                                            repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
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
            if(card == nil)
                NSLog(@"In card not matched else for update");
            self.score -= COST_TO_CHOOSE;
            card.chosen = YES;
        }
    }
}

#pragma mark Helper Methods

//Update score for match
-(void)updateGameForMatch:(Card *)chosenCard forScore:(int)score{
    self.score += score * MATCH_BONUS;
    self.totalTime += MATCH_TIME_BONUS;
    chosenCard.matched = YES;
    
    for(Card *otherCard in chosenCards){
        otherCard.matched = YES;
    }

    [chosenCards removeAllObjects];
}

//Update score and cards status for mismatch
-(void)updateGameForMismatch:(Card *)chosenCard{
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
        self.totalTime--;
        if(self.subTime > 1)
            self.subTime--;
        else{
            if(self.totalTime > SUB_TIME)
                self.subTime = SUB_TIME;
            else
                self.subTime = self.totalTime;
            [self populateGameWithCount:self.cardCount];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reset" object:nil];
        }
    }
    else{//Game Has Ended
        [self.timer invalidate];
        //Update Flags Here or Something
    }
}

-(BOOL)populateGameWithCount:(NSUInteger)count{
    id someId = [self.permanentDeck copy];
    if([someId isKindOfClass:[Deck class]])
        self.deck = (Deck *)someId;
    
    if([self.cards count] != 0){
        NSLog(@"Removing all card before repopulation");
        [self.cards removeAllObjects];
    }
    
    NSLog(@"Repopulating cards in model");
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
