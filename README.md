# Peg Solitaire

## Goals:
1. Let the game run on the terminal
2. Auto-solve the game
3. Make the game more memory efficient than just an array of structs for each position on the board
4. Become more proficient at zig

## Getting Started
1. Download at least zig 0.15
2. Clone the repo:
```
git clone https://github.com/bphilip777/PegSolitaire
```
2. Build on your computer:
    a. What kind of OS? windows or macos or linux = OS
    b. What kind of arch? x86\_64 or aarch64 = ARCH
    c. Run the following based on a and b:
    Example:
    ```
    zig build -Dtarget={ARCH}-{OS} -Doptimize=ReleaseFast
    ```
    d. Your game will now live inside ".../PegSolitaire/zig-out/PegSolitaire.ext"
    e. To run this in the future, you just need to open the PegSolitaire.exe on windows or .so on linux, macos
3. Copy below into your terminal to run it:
    ```zig
        zig run ./.zig-out/
    ```

## Documentation:
- All of it is listed in Documentation.md
- holds all functions + lists their purpose + assumptions
