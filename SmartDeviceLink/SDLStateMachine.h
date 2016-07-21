//
//  SDLStateMachine.h
//  SmartDeviceLink-iOS
//
//  Created by Joel Fischer on 10/30/15.
//  Copyright © 2015 smartdevicelink. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString SDLState;
typedef NSArray<SDLState *> SDLAllowableStateTransitions;

typedef NSString SDLStateMachineNotificationInfoKey;
extern SDLStateMachineNotificationInfoKey *const SDLStateMachineNotificationInfoKeyOldState;
extern SDLStateMachineNotificationInfoKey *const SDLStateMachineNotificationInfoKeyNewState;


/**
 *  This class allows for a state machine to be created with a set of states and allowable transitions. When a transition occurs, the state machine will attempt to call a series of methods on the `target` class.
 *
 *  Additionally, NSNotifications will be fired. The notifications will be of type "com.sdl.notification.statemachine.`TargetClass`". The target class is generated by calling `NSStringFromClass([target Class])`. The payload will contain the transition type, the old state, and new state.
 *
 *  The sequence of events and methods are:
 *  * `[target willLeaveState<old state name>]`
 *  * `[target willTransitionFromState<old state name>ToState<new state name>]`
 *  * The state transitions here
 *  * `[target didTransitionFromState<old state name>ToState<new state name>]`
 *  * `[target didEnterState<new state name>]`
 */
@interface SDLStateMachine : NSObject

@property (copy, nonatomic, readonly) NSDictionary<SDLState *, SDLAllowableStateTransitions *> *states;
@property (copy, nonatomic, readonly) SDLState *currentState;
@property (weak, nonatomic, readonly) id target;

/**
 *  This transition will be sent right after the state changes, but before `didTransition` or `didEnter` method calls occur.
 */
@property (copy, nonatomic, readonly) NSString *transitionNotificationName;

/**
 *  Create a new state machine with these parameters
 *
 *  @param target     The target class state transition messages will be sent to
 *  @param states     A dictionary of states and their allowed transitions
 *  @param initialState The initial state of the state machine
 *
 *  @return An instance of the state machine class
 */
- (instancetype)initWithTarget:(id)target initialState:(SDLState *)initialState states:(NSDictionary<SDLState *, SDLAllowableStateTransitions *> *)states;

/**
 *  Transition to another state when called. If the current state is not allowed to transition to the new state, an exception will occur. If the state machine is already in the called state, no action will occur.
 *
 *  @param state The state to transition to.
 */
- (void)transitionToState:(SDLState *)state;

/**
 *  Return whether or not the current state is the passed state
 *
 *  @param state The state to check
 */
- (BOOL)isCurrentState:(SDLState *)state;

@end

NS_ASSUME_NONNULL_END
