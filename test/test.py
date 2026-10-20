import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer


@cocotb.test()
async def test_counter_charter_d01(dut):
    dut._log.info("Start D01 8-bit counter verification")

    # Initialize all inputs.
    dut.clk.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    # Start clock and hold reset active.
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await Timer(5, units="ns")

    assert int(dut.uo_out.value) == 0, (
        "Initial asynchronous reset failed"
    )

    count = 0

    # Release reset away from the rising clock edge.
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1
    await Timer(2, units="ns")

    async def step(data=0, load=0, up_down=1, en=0):
        nonlocal count

        # Drive inputs before the active clock edge.
        await FallingEdge(dut.clk)
        dut.ui_in.value = data & 0xFF
        dut.uio_in.value = (
            (load << 0)
            | (up_down << 1)
            | (en << 2)
        )

        # Wait for the register and gate-level delays to settle.
        await RisingEdge(dut.clk)
        await Timer(2, units="ns")

        # Update reference model.
        if load:
            count = data & 0xFF
        elif en:
            if up_down:
                count = (count + 1) & 0xFF
            else:
                count = (count - 1) & 0xFF

        actual = int(dut.uo_out.value)
        assert actual == count, (
            f"Expected 0x{count:02X}, got 0x{actual:02X}"
        )

        assert int(dut.uio_out.value) == 0, (
            "uio_out must be zero"
        )
        assert int(dut.uio_oe.value) == 0, (
            "uio_oe must be zero"
        )

    # 1. Asynchronous reset during operation.
    await step(data=0x55, load=1)

    dut.rst_n.value = 0
    await Timer(2, units="ns")
    count = 0

    assert int(dut.uo_out.value) == 0, (
        "Mid-operation asynchronous reset failed"
    )

    # Release reset and wait for it to settle.
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1
    await Timer(2, units="ns")

    # 2. Parallel load.
    await step(data=0xA5, load=1, en=0)
    assert count == 0xA5

    # 3. Count up.
    await step(up_down=1, en=1)
    assert count == 0xA6

    # 4. Count down.
    await step(up_down=0, en=1)
    assert count == 0xA5

    # 5. Hold current value.
    for _ in range(4):
        await step(en=0)
    assert count == 0xA5

    # 6. Load has priority over counting.
    await step(data=0x3C, load=1, up_down=1, en=1)
    assert count == 0x3C

    # 7. Overflow: 255 -> 0.
    await step(data=0xFF, load=1)
    await step(up_down=1, en=1)
    assert count == 0x00, "Overflow 255 -> 0 failed"

    # 8. Underflow: 0 -> 255.
    await step(up_down=0, en=1)
    assert count == 0xFF, "Underflow 0 -> 255 failed"

    # 9. Reproducible randomized testing.
    rng = random.Random(20261020)

    for _ in range(100):
        await step(
            data=rng.randrange(256),
            load=rng.randrange(2),
            up_down=rng.randrange(2),
            en=rng.randrange(2),
        )

    dut._log.info("D01 8-bit counter verification completed")
