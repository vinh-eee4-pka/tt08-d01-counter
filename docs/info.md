## How it works

An 8-bit universal binary counter with enable (`en`), up/down direction (`up_down`), and direct parallel load (`load`) inputs.

## How to test

1. Apply system clock `clk` and set `rst_n = 1`.
2. Set `uio_in[2]` (en) = 1, `uio_in[1]` (up_down) = 1 to test Up Counting.
3. Set `uio_in[1]` (up_down) = 0 to test Down Counting.
4. Set `uio_in[0]` (load) = 1 and apply input data on `ui_in[7:0]` to test Parallel Load.
5. Set `uio_in[2]` (en) = 0 to test Hold Mode.

## External hardware

None
