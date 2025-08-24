# Peg Solitaire

# -- This repo is still experimental --

# Aim: To learn zig by:
# - creating a simple text game
# - handle user interfaces
# - auto-solver
# - Implement different data structures
# - Always follow functions with tests to convey how to use functions
# - Should I have pos and negative moves - all positive moves are negative moves
    - instead have a list of moves -> convert positive or negative on input

# TODO:
1. Create a Board - DONE
2. Choose Moves - DONE
3. Manual Mode:
    - parse CLI arguments
    - check for win/lost conditions - DONE
    - reset board/game - DONE
3. Automatic Mode:
    - search through all move space for all solutions
    - reduce seach space by using symmetries - 4 unique win conditions for a board with 5 rows
4. Create binaries for 3 main oses:
    - Windows
    - Mac
    - Linux

# Get Started!
1. Download zig + add zig to path
2. Clone repo
3. Run the following in your terminal:
``` zig
zig build -Drelease-fast run
```

# Functions List:
createBoard - takes in


# Memory Optimization (Struct Of Arrays):
- reduce # of bytes:
- used null (Total 110 Bytes)
- changed to enum (80 Bytes) - still wasting 15 bytes
- MultiArrayList (48 Bytes)
- swapped above for arrays -> 64 bytes instead
