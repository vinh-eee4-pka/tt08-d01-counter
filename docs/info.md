# 8-bit Universal Counter

## How it works

An 8-bit universal binary counter supporting up/down counting, parallel loading, and hold operations.

## How to test

1. Apply clock `clk` and set `rst_n = 1`.
2. Set `ui[0]` (en) = 1, `ui[1]` (up_down) = 1 for Up Counting.
3. Set `ui[1]` (up_down) = 0 for Down Counting.
4. Set `ui[2]` (load) = 1 and apply input data on `uio[7:0]` for Parallel Load.
5. Set `ui[0]` (en) = 0 for Hold Mode.

## External hardware

None
