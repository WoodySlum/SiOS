/*
 Copyright (C) 2011 by Stuart Carnie
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "iCadeReaderView.h"

/*
 Haut : z, e
 Droite : d, c
 Bas : x, w
 Gauche : q, a
 Select : k, p
 Start : j, n
 Triangle : y, t
 Rond : u, f
 Croix : h, r
 Carré : i, ,
 */

// iCade Querty
static const char *ON_STATES  = "wdxayhujikol";
static const char *OFF_STATES = "eczqtrfnmpgv";

// iCade Azerty (change it if you're using AZERT keyboard - comment lines above)
//static const char *ON_STATES  = "zdxqyhujikol";
//static const char *OFF_STATES = "ecwatrfn,pgv";

// Keyboard (WIP)
static bool keyboard = false;
//static const char *ON_STATES  = "zdsqyhujikol";

@interface iCadeReaderView()

- (void)didEnterBackground;
- (void)didBecomeActive;

@end

@implementation iCadeReaderView

@synthesize iCadeState=_iCadeState, delegate=_delegate, active;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    inputView = [[UIView alloc] initWithFrame:CGRectZero];
    //keyDict = [[NSMutableDictionary alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    // Detect keyboard type : FR Keyboard is different !
    if ([[UITextInputMode currentInputMode].primaryLanguage isEqualToString:@"fr-FR"]) {
        ON_STATES = "zdxqyhujikol";
        OFF_STATES = "ecwatrfn,pgv";
    }
    
    return self;
}

- (void)dealloc {
    //[keyDict release];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [super dealloc];
}

- (void)didEnterBackground {
    if (self.active)
        [self resignFirstResponder];
}

- (void)didBecomeActive {
    if (self.active)
        [self becomeFirstResponder];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)setActive:(BOOL)value {
    if (active == value) return;
    
    active = value;
    if (active) {
        [self becomeFirstResponder];
    } else {
        [self resignFirstResponder];
    }
}

- (UIView*) inputView {
    return inputView;
}

- (void)setDelegate:(id<iCadeEventDelegate>)delegate {
    _delegate = delegate;
    if (!_delegate) return;
    
    _delegateFlags.stateChanged = [_delegate respondsToSelector:@selector(stateChanged:)];
    _delegateFlags.buttonDown = [_delegate respondsToSelector:@selector(buttonDown:)];
    _delegateFlags.buttonUp = [_delegate respondsToSelector:@selector(buttonUp:)];
}

#pragma mark -
#pragma mark UIKeyInput Protocol Methods

- (BOOL)hasText {
    return NO;
}

- (void)insertText:(NSString *)text {
    
    char ch = [text characterAtIndex:0];
    char *p = strchr(ON_STATES, ch);
    NSString *key;
    
    bool stateChanged = false;
    if (!keyboard) {
        key = [NSString stringWithFormat:@"%s", p];
        NSLog(@"iCade detected key : %c", ch);
        if (p) {
            int index = p-ON_STATES;
            _iCadeState |= (1 << index);
            stateChanged = true;
            
            if (_delegateFlags.buttonDown) {
                [_delegate buttonDown:(1 << index)];
            }
        } else {
            p = strchr(OFF_STATES, ch);
            if (p) {
                int index = p-OFF_STATES;
                _iCadeState &= ~(1 << index);
                stateChanged = true;
                if (_delegateFlags.buttonUp) {
                    [_delegate buttonUp:(1 << index)];
                }
            }
            
        }
    } else {
        // WIP : To support bluetooth keyboard
        /*key = [NSString stringWithFormat:@"%c", ch];
        if ([K_ON_STATES objectForKey:key]) {
            if ([[K_ON_STATES objectForKey:key] isEqualToString:@"0"]) {
                [K_ON_STATES setValue:@"1" forKey:key];
                int index = p-ON_STATES;
                _iCadeState |= (1 << index);
                stateChanged = true;
                
                if (_delegateFlags.buttonDown) {
                    [_delegate buttonDown:(1 << index)];
                }
                
            } else {
                int index = p-OFF_STATES;
                _iCadeState &= ~(1 << index);
                stateChanged = true;
                if (_delegateFlags.buttonUp) {
                    [_delegate buttonUp:(1 << index)];
                }
                
                [K_ON_STATES setValue:@"0" forKey:key];
            }
        }*/
    }
    
    if (stateChanged && _delegateFlags.stateChanged) {
        [_delegate stateChanged:_iCadeState];
    }
    
    static int cycleResponder = 0;
    if (++cycleResponder > 20) {
        // necessary to clear a buffer that accumulates internally
        cycleResponder = 0;
        [self resignFirstResponder];
        [self becomeFirstResponder];
    }
}

- (void)deleteBackward {
    // This space intentionally left blank to complete protocol
}

@end
