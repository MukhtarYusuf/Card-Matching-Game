//
//  HighScore+CoreDataProperties.h
//  Matchima
//
//  Created by Mukhtar Yusuf on 8/19/17.
//  Copyright © 2017 Mukhtar Yusuf. All rights reserved.
//

#import "HighScore+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface HighScore (CoreDataProperties)

+ (NSFetchRequest<HighScore *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *name;
@property (nonatomic) int32_t rank;
@property (nonatomic) int32_t value;

+ (void)insertHighScoreWithRank:(int)rank name:(NSString *)name value:(int)value andContext:(nonnull NSManagedObjectContext *)context;
@end

NS_ASSUME_NONNULL_END
