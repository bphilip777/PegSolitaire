# Peg Solitaire

# How to play
1. Download zig - add zig to path
2. Download repo
3. Run the following in your terminal:
``` zig
zig build -Drelease-fast run
```

## GOALS:
1. Play game to failure - Done
2. Search algorithm - Done
3. Play game to success - Done
4. Play game with new starts
5. Save search space
6. Reduce search space
    - use previous searches
    - using rotations/symmetries
7. Data Structure
    - Array of Bools - uses u8s = memory inefficient
    - BitSet
8. Add Version Control For Zig - At Least 0.15+


# TODO:
1. Create Board
 dynamically sized board
 idx - where hole is placed
 identify possible moves
2. Choose moves
 need to follow a chain until win/lose
3. Repeat 2 for all possible combinations
 need to unwind to previous board position and choose unchosen move
