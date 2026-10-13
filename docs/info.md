# 8-bit Universal Counter

## How it works

An 8-bit universal binary counter with enable (`en`), up/down direction (`up_down`), and direct parallel load (`load`) inputs.

## How to test

1. Apply system clock `clk` and set `rst_n = 1`.
2. Set `ui[0]` (en) = 1, `ui[1]` (up_down) = 1 to test Up Counting.
3. Set `ui[1]` (up_down) = 0 to test Down Counting.
4. Set `ui[2]` (load) = 1 and apply input data on `uio[7:0]` to test Parallel Load.
5. Set `ui[0]` (en) = 0 to test Hold Mode.

## External hardware

None
