# Table Of Contents
1. [Introduction](#introduction)
2. [Functions List](#function)

## Introduction
### Definitions
1. Board = Used to play the game
2. Helpers = List of functions to compute basic miscellaneous tasks
3. Lexer = Tokenizes user string input into tokens
4. Parser = Parses tokens into grammar the board can use to make decisions
5. Game = Program deciding + managing game rules, inputs, and outputs
6. Making a Move = Moving a peg over another peg to an empty spot
    a. Negative Move: From the empty spot, add a peg + 2 empty spots in a direction
    b. Positive Move: Moving a peg over another peg to an empty spot
    c. Given a Board of size 5, with 1 unset peg at index 0:
        a Negative Move of (0,0) to (2,0) = Positive Move of (2,0) to (0,0)
7. Direction: direction a peg can move
    - Left, UpLeft, UpRight, Right, DownRight, DownLeft
8. Move: direction + index
9. Seach: index where target would be found if it did exist + whether it exists 
10. Position: row and column a peg is on
11. Index: Index a peg is on

### Files List
1. Board: contains all functions related to creating and using the board
2. Helpers: Miscellaneous functions that help all other files
3. Lexer: Helps parse input strings into tokens
4. Parser: Converts the input tokens into grammar usable by the game system
5. Game: Contains game logic, i/o, board, error handling of different board states
6. Main: Just used to pass an allocator

## Functions List
### Board Functions:
1. createBoard:
    - comptime function to create the board based on number of input rows
    - checks that number of rows is atleast 3 b/c it is impossible to play with fewer than 3 rows
    - checks that number of rows does not exceed what a u16 can hold = overflow error prevention
    - Board:
        - struct returned by create board
        - board = bitset of board state = memory efficient + fast to check board state
        - moves = list of possible moves
        - chosen idxs = previously chosen board positions to make a negative move
2. init
    - creates a new board given an idx
    - idx will be set off, all other positions will be set on
    - checks that index is within bounds of Board size 
3. printBoard
    - prints out current board state
4. computeAllMoves
    - brute force checks for all possible moves
    - useful for small boards
5. computeOptimally
    - checks the fewest number of pegs affected by any given move
    - useful for large boards
6. hasMove
    - takes in a list of 3 indices
    - checks that each index is within board size
    - returns true for either a possible positive ro negative move
7. chooseMove
    - wrapper for chooseMoveIdx or chooseMovePos
    - takes in an input and direction
    - input can be and index or position
    - direction must be defined by Helpers.Direction
8. chooseMovePos
    - converts input position to an index
    - runs chooseMoveIdx
8. chooseMoveIdx
    - computes whether or not the indices in that direction are valid
    - computes whether the move is a positive or negative one
    - updates chosen index, chosen direction, and board
    - updates possible moves
9. resetBoard
    - resets the board and board state to the start
10. undo
    - if board is at start state, returns
    - else: undoes the last chosen index up until the start, at which it simply returns
11. redo
    - if board is at start state, returns
    - else: undoes the last undone move 
12. setNegMove
    - checks if inputs are correct
    - performs a - move
13. setPosMove
    - checks if inputs are correct
    - performs a + move
14. unsetNegMove
    - checks if inputs are correct
    - undoes a - move
15. unsetPosMove
    - checks if inputs are correct
    - undoes a + move
16. isValidIdx
    - checks if input index is within board capacity
17. getLeft
    - chesk if a position left of current position exists:
    - if yes, returns it
18. getUpLeft
    - chesk if a position up left of current position exists:
    - if yes, returns it
19. getUpRight
    - chesk if a position up right of current position exists:
    - if yes, returns it
20. getRight
    - chesk if a position right of current position exists:
    - if yes, returns it
21. getDownRight
    - chesk if a position down right of current position exists:
    - if yes, returns it
22. getDownLeft
    - chesk if a position down left of current position exists:
    - if yes, returns it
23. getRotation
    - takes in a position, direction, rotation
    - if position does not exists, returns that new position cannot exist either
    - if new position not exist, returns null
    - makes identifying a position in a direction exists or not
24. isGameOver
    - checks whether you won or lost or game is still running
25. isWon
    - checks whether 1 peg left over
26. numMovesLeft
    - computes the number of remaining possible moves
27. isLost
    - checks whether there are no moves left and more than 1 peg left
28. reset
    - resets board back to starting state
    - all pegs are back except start
    - undoes all moves
    - recomputes starting moves
    - resets chosen idxs + chosen dirs
29. printMoves
    - prints all possible moves in a table
30. hasRemainingMoves
    - checks whether any moves still exist
    - uses xor trick = faster than searching for all remaining moves + directions
31. getMove
    - for auto-solver
    - gets first move found
    - otherwise returns direction as none for no moves left
32. flip
    - optimization for auto-solver: board is horizontally symmetrical
    - flips the board horizontally
    - checks what the board index is at that position
    - removes those moves from search space
33. changeStart
    - abstracts the inputs to change start based on idx or position
34. changeStartPos
    - takes in a position, converts to an index
    - runs changeStartIdx
35. changeStartIdx
    - checks if board is at the start - yes = continue
    - checks whether new start position is within bounds - yes = continue
    - changes which peg is gone at start of game
36. dfs
    - basic depth first search
    - for auto-solver - finds first solution
37. dfsAll
    - basic depth first search
    - for auto-solver - finds all solutions
38. binarySearch
    - basic binary search
    - used to find a previous board state based on number of pegs (represented as a u16)

### Helper Fns
1. numCharsFromDigit
    - used for printMoves to get spacing correct
2. numCharsFromIdx
    - wrapper for numCharsFromDigit
    - used for printMoves to get spacing correct
3. numCharsFromPos
    - wrapper for numCharsFromDigit
    - used for printMoves to get spacing correct
4. triNum
    - compute number of pegs from top to that row
5. invTriNum
    - given a triangular number, return the row that peg is on
    - computed using a formula = faster for larger inputs
6. invTriNum2
    - computed using an algorithmic approach
    - faster for smaller inputs = no compute heavy fns
7. Position
    a. eql = checks if two positions are equal
    b. dst = checks dst between two positions
    c. flip = return the peg on the other side of the board
    d. dir = direction from self to other
8. posFromIdx
    - return a position given an index
9. idxFromFlip
    - get the index of a flipped position
10. idxFromPos
    - get the index of a position
11. Rotation
    - opposite - get the opposite rotation
12. Direction
    a. opposite = get opposite direction
    b. flip = get flipped direction
    c. parse = convert a string to a direction - otherwise return none
    d. dir = return the direction from first position to second position
13. numMoves
    - compute number of moves inside an enumset of moves
14. getAllMoves
    - computes all moves a list of enumsets of moves contains
15. numChars
    - used for printMoves to compute formatting correctly based on number of possible moves
16. formatMove
    - formats all possible moves provided into a list
17. flipFromIdx
    - returns the flipped index of the current index

### Lexer Fns
1. Lexer
    - converts input string into lexer tokens
    - tokens = start + end + tag
    - tag = null, empty, num, alpha, help
        - empty = no input
        - null = uninitialized
        - num = number
        - alpha = alphabetic input
        - help = ? input
2. printError
    - used to print errors when debugging
3. resetTokens
    - resets all tokens to nothing - used on initialization of tokens
4. numTokens
    - computes the number of non-null tokens

### Parser Fns
1. Parser
    - checks for valid tags:
        - empty = no input
        - start = change board starting index
        - auto = auto-solves the board
        - help = prints help statement
        - redo = redoes an undone move
        - undo = undoes a move
        - reset = resets the board
        - quit = quits the game
        - moves = shows all possible moves
        - num = part of either an index or position
        - dir = Helpers.Direction
    - returns the list of possible command and their inputs

### Game
1. manual
    - runs the game in manual mode for users
    - has to enforce the rules of peg solitaire-
    - has to solve a position if a player gets stuck
    - has to print the board
    - has to print all possible moves
    - has to check if game is over or not
    - handles errrors without crashing the game
    - provide a help statement
    - greet the user
    - interpret parsed tokens into internal game commands
    - enable user to input instructions and receive outputs
2. auto
    - auto solves the game
    - used for builder to check whether game has other solutions or not
3. greeting
    - greets the player
4. help
    - provides a user friendly help statement on what is interactable
    - how to understand the board state
    - what to do
