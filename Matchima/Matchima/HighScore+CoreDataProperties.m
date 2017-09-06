//
//  HighScore+CoreDataProperties.m
//  Matchima
//
//  Created by Mukhtar Yusuf on 8/19/17.
//  Copyright © 2017 Mukhtar Yusuf. All rights reserved.
//

#import "HighScore+CoreDataProperties.h"

@implementation HighScore (CoreDataProperties)

+ (NSFetchRequest<HighScore *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"HighScore"];
}

+ (void)insertHighScoreWithRank:(int)rank name:(NSString *)name value:(int)value andContext:(nonnull NSManagedObjectContext *)context{
    HighScore *highScore = [NSEntityDescription insertNewObjectForEntityForName:@"HighScore" inManagedObjectContext:context];

    highScore.rank = rank;
    highScore.name = name;
    highScore.value = value;
}

@dynamic name;
@dynamic rank;
@dynamic value;

@end
