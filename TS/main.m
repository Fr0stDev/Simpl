//
//  main.m
//  TS
//
//  Created by Guillermo Morán on 11/10/16.
//  Copyright © 2016 GMoran. All rights reserved.
//

#import <Foundation/Foundation.h>

static BOOL canExit;
static int repeatCount = 1;

// Global Variables
static NSString* output;
static NSString* sum;
static NSString* difference;
//static NSString* quotient;
//static NSString* product;

/*
 ====================================
 
 INTERFACES
 
 ====================================
 */

#define TOO_MANY_ARGUMENTS    @"Too many arguments."
#define NOT_ENOUGH_ARGUMENTS  @"Not enough arguments."
#define FILE_NOT_FOUND        @"File not found."
#define INVALID_FUNCTION      @"Invalid function call."
#define INVALID_ARGUMENT      @"Invalid argument."


@interface TSUtils : NSObject {}
+ (BOOL)isNumeric:(NSString*)checkText;
+ (BOOL)string:(NSString*)string containsSubstring:(NSString*)substring;
+ (BOOL)startsWithUppercase:(NSString*)text;
@end

@interface TSMain : NSObject {}
+ (void)println:(NSString*)string;
+ (NSString*)getUserInput;
+ (BOOL)parseCommand:(NSString*)input;
@end

@interface TSStack : NSObject {
    NSMutableArray* stackArray;
}

- (id)init;
- (void)push:(id)obj;
- (id)pop;
- (BOOL)isEmpty;

@end

@interface TSVariableStorage : NSObject {
    NSMutableDictionary* variableDict;
}

+ (instancetype)sharedInstance;
- (id)init;

@end

@interface TSUserDefinedFunctionStorage : NSObject {
    NSMutableDictionary* functionDict;
}

+ (instancetype)sharedInstance;
- (id)init;

@end

@interface TSFunctions : NSObject {}

+ (void)print:(NSArray*)args;
+ (void)exit;
+ (void)audit:(NSArray*)args;

@end

/*
 ====================================
 
 TSUtils:
 
 Internal functions used to facilitate simple tasks,
 such as string operations.
 
 ====================================
 */

@implementation TSUtils

+ (BOOL)string:(NSString*)string containsSubstring:(NSString*)substring {
    
    NSRange range = [string  rangeOfString: substring options: NSCaseInsensitiveSearch];
    //NSLog(@"found: %@", (range.location != NSNotFound) ? @"Yes" : @"No");
    
    if (range.location != NSNotFound) {
        return YES;
    }
    return NO;
}

+ (BOOL)isNumeric:(NSString*)checkText {
    return [[NSScanner scannerWithString:checkText] scanFloat:NULL];
}

+ (BOOL)startsWithUppercase:(NSString*)text {
    BOOL isUppercase = [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[text characterAtIndex:0]];
    
    return isUppercase;
}

@end

/*
 ====================================
 
 TSVariableStorage:
 
 Class used to store and manage variable names and values
 from within the interpreter. Variable names can be created,
 stored and changed, but not deleted.
 
 ====================================
 */

@implementation TSVariableStorage

+ (instancetype)sharedInstance
{
    static TSVariableStorage *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[TSVariableStorage alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    
    if (self) {
        variableDict = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (BOOL)addVariable:(NSString*)variable withValue:(id)value {
    
    //if ([variableDict objectForKey:variable]) {
        //[TSMain println:[NSString stringWithFormat:@"Variable already exists: %@", variable]];
      //  [self changeVariable:variable withValue:value];
        //return YES;
    //}
    
    value = [value stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    [variableDict setObject:value forKey:variable];
    return YES;
}

- (id)getValueFromVariable:(NSString*)variable {
    
    id ret = [variableDict objectForKey:variable];
    
    if (ret) {
        return ret;
    }
    
    [TSMain println:[NSString stringWithFormat:@"Variable does not exist: %@", variable]];
    return nil;
    
}

@end

@implementation TSUserDefinedFunctionStorage

+ (instancetype)sharedInstance
{
    static TSUserDefinedFunctionStorage *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[TSUserDefinedFunctionStorage alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    
    if (self) {
        functionDict = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (BOOL)addFunction:(NSString*)functionName withArgs:(NSArray*)args {
    
    if ([functionDict objectForKey:functionName]) {
        
        [TSMain println:[NSString stringWithFormat:@"Function already exists: %@", functionName]];
    
        return NO;
    }
    
    //args = [args stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    [functionDict setObject:args forKey:functionName];
    return YES;
}

- (NSArray*)getActualFunctionCallArray:(NSString*)functionName {
    return [functionDict objectForKey:functionName];
}

- (BOOL)functionExists:(NSString*)functionName {
    
    if ([functionDict objectForKey:functionName]) {
        
        return YES;
    }
    return NO;

}

@end

/*
 ====================================
 
 TSStack:
 
 Interpreter stack, mainly used to prioitize and execute
 functions from a file in a correct and organized manner,
 without dealing with arrays and array functions.
 
 ====================================
 */

@implementation TSStack

- (id)init {
    self = [super init];
    
    if (self) {
        stackArray = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)push:(id)obj {
    [stackArray addObject:obj];
    
}
- (id)pop {
    
    if (![self isEmpty]) {
        id returnValue = stackArray[stackArray.count -1];
        [stackArray removeObjectAtIndex:stackArray.count -1];
        
        return returnValue;
    }
    return nil;
}

- (BOOL)isEmpty {
    
    if (stackArray.count == 0) {
        return YES;
    }
    return NO;
}

@end

/*
 ====================================
 
 TSMain:
 
 Class used for internal interpreter functions, such as
 printing text, taking user input, parsing commands, and
 more.
 
 ====================================
 */

@implementation TSMain


/*
 * Prints a new line to the console
 */

+ (void)println:(NSString*)string {
    const char *cString = [string cStringUsingEncoding:NSASCIIStringEncoding];
    printf("%s", cString);
    printf("\n");
}

/*
 * Takes user input for commands
 */

+ (NSString*)getUserInput {
    char input[200];
    printf("> ");
    fgets(input, 200, stdin);
    
    NSString *ret = [[NSString alloc] initWithUTF8String:input];
    
    return ret;
}

/*
 * Parses commands passed in to the console:
 *
 * Separates commands by arguments and function names
 * Replaces variable names with their corresponding values
 *
 * Variable names must start with a capital letter
 *
 */

+ (BOOL)parseCommand:(NSString*)input {
    
    NSArray *arguments = [input componentsSeparatedByString:@" "];
    
    NSString* function = arguments[0];
    function = [[function componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@""];
    
    NSMutableArray *functionArgsWithVars = [arguments mutableCopy];
    
    [functionArgsWithVars removeObjectAtIndex:0]; //remove the first item (function name) for retreiving arguments
    
    [functionArgsWithVars removeObject:@"\n"]; //remove new line from arguments
    
    
    // Construct a new array, replacing variables with their corresponding values
    
    NSMutableArray* functionArgs = [[NSMutableArray alloc] init];
    
    for (NSString* string in functionArgsWithVars) {
        
        NSString* s = [string stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        
        
        if ([TSUtils startsWithUppercase:s] && (![s isEqualToString:@"Sum"]) && (![s isEqualToString:@"Difference"]) && (![s isEqualToString:@"Out"]) && (![function isEqualToString:@"func"]) && (![function isEqualToString:@"var"]) && (![function isEqualToString:@"whatis"]) && (![function isEqualToString:@"repealAndReplace"])) {
            
            TSVariableStorage* varStorage = [TSVariableStorage sharedInstance];
            
            NSString* value = [varStorage getValueFromVariable:[s stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
            
            if (value) {
                [functionArgs addObject:value];
            }
            else {
                return NO;
            }
            
        }
        
        else if ([s isEqualToString:@"Out"]) {
            if (output) {
                [functionArgs addObject:output];
            }
        }
        
        else if ([s isEqualToString:@"Sum"]) {
            if (sum) {
                [functionArgs addObject:sum];
            }
        }
        
        else if ([s isEqualToString:@"Difference"]) {
            if (difference) {
                [functionArgs addObject:difference];
            }
        }
        
        else {
            [functionArgs addObject:s];
        }
        
    }
    
    TSStack* functionStack = [[TSStack alloc] init];
    
    if (repeatCount == 1) {
        [functionStack push:function];
        //NSLog(@"a");
    }
    else if (repeatCount > 1) {
        while (repeatCount >= 1) {
            [functionStack push:function];
            
            repeatCount --;
        }
    }
    
    repeatCount = 1; //reset repeat counter
    
    while (![functionStack isEmpty]) {
        NSString* functionCall = [functionStack pop];
        
        TSUserDefinedFunctionStorage* functionStorage = [TSUserDefinedFunctionStorage sharedInstance];
        
        SEL selector = NSSelectorFromString([NSString stringWithFormat:@"%@", functionCall]);
        SEL selectorWithArgs = NSSelectorFromString([NSString stringWithFormat:@"%@:", functionCall]);
        
        if ([TSFunctions respondsToSelector:selector]) {
            
            [TSFunctions performSelector:selector];
            
        }
        
        else if ([TSFunctions respondsToSelector:selectorWithArgs]) {
            
            [TSFunctions performSelector:selectorWithArgs withObject:functionArgs];
      
        }
        
        
        else if ([functionStorage functionExists:function]) {
            
            NSMutableArray* actualFunctionCall = [[functionStorage getActualFunctionCallArray:function] mutableCopy];
            
            NSString* functionName = actualFunctionCall[0];
            NSString* funcCall = @"";
            [actualFunctionCall removeObjectAtIndex:0];
            
            
            for (NSString* str in actualFunctionCall) {
                funcCall = [NSString stringWithFormat:@"%@ %@", funcCall, str];
            }
       
            
            [self parseCommand:[NSString stringWithFormat:@"%@%@", functionName, funcCall]];
            
            /*
            
            [actualFunctionCall removeObjectAtIndex:0]; //This is now the function arguments
            
            NSLog(@"%@ : %@", functionName, actualFunctionCall);
            
            SEL definedSelector = NSSelectorFromString([NSString stringWithFormat:@"%@", functionName]);
            SEL definedSelectorWithArgs = NSSelectorFromString([NSString stringWithFormat:@"%@:", functionName]);
            
            
            if ([TSFunctions respondsToSelector:definedSelector]) {
                [TSFunctions performSelector:definedSelector];

            }
            else if ([TSFunctions respondsToSelector:definedSelectorWithArgs]) {
                [TSFunctions performSelector:definedSelectorWithArgs withObject:actualFunctionCall];

            }
            else {
                [TSMain println:[NSString stringWithFormat:@"Invalid Function Call: %@", function]];
                return NO;
            }
             */
            
        }
             
        
        else {
            
            [TSMain println:[NSString stringWithFormat:@"Invalid Function Call: %@", function]];
            return NO;
        }
             

    }

    return YES;
}

@end

/*
 ====================================
 
 TSFunctions:
 
 Public scripting language functions. As new functions
 are added in this class, they become available for
 the end user to execute in their own programs.
 
 ====================================
 */

@implementation TSFunctions

/*
 * Declares a new function
 * Takes unlimited arguments: functionName arguments
 * Example usage: "func functionName add 2 1"
 */

+ (void)func:(NSArray*)args {
    
    if (args.count < 1) {
        [TSMain println:@"Not enough arguments."];
        return;
    }
    
    TSUserDefinedFunctionStorage* functionStorage = [TSUserDefinedFunctionStorage sharedInstance];
    
    NSString* functionName = args[0];
    
    NSMutableArray* newFunctionArguments = [args mutableCopy];
    [newFunctionArguments removeObjectAtIndex:0];
    
    if ([functionStorage functionExists:functionName]) {
        [TSMain println:[NSString stringWithFormat:@"You cannot define the function %@ : It already exists.", functionName]];
        return;
    }
    
    
    [functionStorage addFunction:functionName withArgs:newFunctionArguments];
}

/*
 * Prints a new line
 * Takes no arguments
 * Example usage: "newline"
 */

+ (void)newline {
    [TSMain println:@"\n"];
}

/*
 * Takes in user input
 * Takes 1 argument: prompt
 * Example Usage: input please enter your name:
 */

+ (void)input:(NSArray*)args {
    
    if (args.count < 1) {
        [TSMain println:@"Not enough arguments."];
        return;
    }
    
    
    NSString* argument = @"";
    
    for (NSString* s in args) {
        argument = [NSString stringWithFormat:@"%@ %@", argument, s];
    }
    argument = [argument stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    const char *prompt = [argument cStringUsingEncoding:NSASCIIStringEncoding];
    
    char input[200];
    printf("%s : ", prompt);
    fgets(input, 200, stdin);
    
    NSString *stringToSave = [[NSString alloc] initWithUTF8String:input];
    
    output = stringToSave;
}

/*
 * Prints the value of a given variable
 * Takes 1 argument: variable name
 * Example Usage: whatis X
 */

+ (void)whatis:(NSArray*)args {
    if (args.count < 1) {
        [TSMain println:@"Not enough arguments."];
        return;
    }
    
    if (args.count > 1) {
        [TSMain println:@"Too many arguments."];
        return;
    }
    
    NSString* var = [args[0] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    [TSMain println:[NSString stringWithFormat:@"%@ is %@",var , [[TSVariableStorage sharedInstance] getValueFromVariable:var]]];
}

/*
 * Repeats the next command the given number of times (> 0)
 * Takes 1 argument: int
 * Example usage: repeat 5
 */

+ (void)loop:(NSArray*)args {
    if (args.count < 1) {
        [TSMain println:@"Not enough arguments."];
        return;
    }
    
    if (args.count > 1) {
        [TSMain println:@"Too many arguments."];
        return;
    }
    
    repeatCount = [args[0] intValue];
    
    if (repeatCount == 0) {
        repeatCount = 1;
        [TSMain println:@"You can't do that."];
        [TSFunctions exit];
    }
    
}


/*
 * Sets the value of a new variable
 * Takes 2 arguments: variable name, value
 * Example usage: make X 2
 */

+ (void)var:(NSArray*)args {
    
    NSString* var = [args[0] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    if ([var isEqualToString:@"Out"]) {
        [TSMain println:@"Variable name 'Out' cannot be used."];
        return;
    }
    
    if ([var isEqualToString:@"Sum"]) {
        [TSMain println:@"Variable name 'Sum' cannot be used."];
        return;
    }
    
    if ([var isEqualToString:@"Difference"]) {
        [TSMain println:@"Variable name 'Difference' cannot be used."];
        return;
    }
    
    if (![TSUtils startsWithUppercase:args[0]]) {
        [TSMain println:[NSString stringWithFormat:@"Variable '%@' should start with a capital letter.", args[0]]];
        return;
    }
    
    if (args.count < 2) {
        [TSMain println:@"Not enough arguments."];
        return;
    }
    
    // args[0] = variable name
    
    TSVariableStorage* vars = [TSVariableStorage sharedInstance];
    
    if (args.count >= 3) {
        if ([TSUtils isNumeric:args[1]]) {
            [TSMain println:@"Too many arguments."];
            return;
        }
        else {
            NSString* string = @"";
            for (int i = 1; i < args.count; i++) {
                string = [NSString stringWithFormat:@"%@ %@", string, args[i]];
            }
            
            
            if (![vars addVariable:args[0] withValue:string]) {
                return;
            }
        }
    }
    
    else if (args.count == 2) {
        
        
        NSString* arg1 = args[1];
        if (![vars addVariable:args[0] withValue:arg1]) {
            return;
        }
    }
    
    
    //[TSMain println:[NSString stringWithFormat:@"%@ is now %@", args[0], [vars getValueFromVariable:args[0]]]];
    
}

/*
 * Pauses the program for a given amount of seconds
 * Takes 1 argument: int
 * Example usage: pause 3
 */

+ (void)pause:(NSArray*)args {
    if (args.count > 1) {
        [TSMain println:@"Too many arguments."];
        return;
    }
    
    if (![TSUtils isNumeric:args[0]]) {
        [TSMain println:[NSString stringWithFormat:@"Invalid Argument: %@", args[0]]];
        return;
    }
    
    int seconds = [args[0] intValue];
    int count = 0;
    
    while (count <= seconds) {
        sleep(1);
        
        if (count == seconds) {
            [TSMain println:@""];
        }
        else {
            printf(".");
        }
        
        count++;
    }
    
}

/*
 * Adds all given numbers and returns a value
 * Takes unlimited arguments
 * Example usage: add 1 2 3 4
 * Stores result in "Sum" variable
 */

+ (void)add:(NSArray*)args {
    float result = 0;
    
    for (int i = 0; i < args.count; i++) {
        
        if (![TSUtils isNumeric:args[i]]) {
            
            if ([TSUtils startsWithUppercase:args[i]]) {
                
                NSString* value = [[TSVariableStorage sharedInstance] getValueFromVariable:[NSString stringWithFormat:@"%i", i]];
                result = result + [value floatValue];
            }
            else {
                [TSMain println:[NSString stringWithFormat:@"Invalid Argument: %@", args[i]]];
                break;
            }
            
        }
        else {
            result = result + [args[i] floatValue];
        }
        
    }
    
    sum = [NSString stringWithFormat:@"%.02f", result];
    //[TSMain println:[NSString stringWithFormat:@"%.02f", result]];
}

/*
 * Subtracts all given numbers and returns a value
 * Takes unlimited arguments
 * Example usage: add 1 2 3 4
 * Stores result in "Difference" variable
 */

+ (void)subtract:(NSArray*)args {
    float result = 0;
    
    for (int i = 0; i < args.count; i++) {
        
        if (![TSUtils isNumeric:args[i]]) {
            [TSMain println:[NSString stringWithFormat:@"Invalid Argument: %@", args[i]]];
            break;
        }
        
        if (i == 0) {
            result = [args[0] floatValue];
        }
        else {
            result = result - [args[i] floatValue];
        }
        
    }
    difference = [NSString stringWithFormat:@"%.02f", result];
}

/*
 * Prints a help page
 * Takes no arguments
 * Example usage: help
 */

+ (void)help {
    
    //[TSMain println:@"\n"];
    [TSMain println:@"Please visit http://gmoran.me/TrumpSpeak for API Documentation."];
    //[TSMain println:@"\n"];
}

/*
 * Prints a line of text
 * Takes unlimited arguments
 * Example usage: print hello world
 */

+ (void)print:(NSArray*)args {
    NSString* stringToPrint = @"";
    
    for (int i = 0; i < args.count; i++) {
        
        stringToPrint = [NSString stringWithFormat:@"%@ %@", stringToPrint, args[i]];
        
        stringToPrint = [[stringToPrint componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@""];
    }
    
    [TSMain println:stringToPrint];
    
}

/*
 * Exits the program
 * Takes no arguments
 * Example usage: exit
 */

+ (void)exit {
    canExit = YES;
}

/*
 * Reads a file from the system
 * Takes 1 arguments
 * Example usage: file /path/to/file.great
 */

+ (void)file:(NSArray*)args {
    
    if (args.count > 1) {
        [TSMain println:@"One file at a time, please."];
        return;
    }
    else if (args.count == 0) {
        [TSMain println:@"No arguments provided."];
        return;
    }
    
    if (![[args[0] stringByReplacingOccurrencesOfString:@"\n" withString:@""] hasSuffix:@".simpl"]) {
        [TSMain println:@"Only .simpl files are allowed."];
        return;
    }
    
    
    // get a reference to our file
    NSString *filePath = args[0];
    
    //remove newline character from string
    filePath = [[filePath componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@""];
    
    //NSFileManager* fileManager;
    
    //if (![fileManager fileExistsAtPath:filePath]) {
    //    [TSMain println:[NSString stringWithFormat:@"File does not exist :: %@", filePath]];
    //}
    
    NSString *fileContentsStr = [[NSString alloc]initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    NSCharacterSet *separator = [NSCharacterSet newlineCharacterSet];
    NSArray *functionsArray = [fileContentsStr componentsSeparatedByCharactersInSet:separator];
    
    // Add functions to a stack in reversed order
    
    NSArray* reversed = [[functionsArray reverseObjectEnumerator] allObjects];
    
    TSStack* functionStack = [[TSStack alloc] init];
    
    
    for (NSString* functionCall in reversed) {
        
        if (![functionCall isEqualToString:@""]) {
            [functionStack push:functionCall];
        }
    }
    
    while (![functionStack isEmpty]) {
        NSString* nextFunction = [functionStack pop];
        
        if (![TSMain parseCommand:nextFunction]) {
            break;
        }
        
    }
}


@end

/*
 ====================================
 
 MAIN FUNCTION:
 
 Runs a loop that continues to ask the user for input
 until the exit command is called.
 
 ====================================
 */

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        canExit = NO;
        repeatCount = 1;
        
        if (argc > 1) {
            //[TSMain println:@"\n"];
            [TSMain println:@"Too many arguments provided. Try again with no arguments."];
            //[TSMain println:@"\n"];
            return 0;
        }
        
        [TSMain println:@"\n"];
        [TSMain println:@"======== MAKE PROGRAMMING GREAT AGAIN ========"];
        
        while (!canExit) {
            
            NSString* userInput = [TSMain getUserInput];
            [TSMain parseCommand:userInput];
        }
        
    }
    return 0;
}

