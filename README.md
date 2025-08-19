# Peg Solitaire

# -- This repo is still experimental --

# Aim: To learn zig by:
# - creating a game
# - handle user interfaces
# - auto-solver
# - Implement different data structures

# TODO:
1. Create a Board - DONE
2. Choose Moves - DONE
3. Manual Mode:
    - parse CLI arguments
    - check for win/lost conditions
    - reset board/game
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
