import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge

@cocotb.test()
async def test_counter_charter_d01(dut):
    dut._log.info("Start Charter D01 8-bit Universal Counter Verification")

    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # Khởi tạo giá trị ban đầu
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 5)
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)

    # 1. Reset Test
    assert int(dut.uo_out.value) == 0, f"Reset failed: {int(dut.uo_out.value)}"

    # 2. Parallel Load Test (load=1, up_down=0, en=1 -> uio = 0b00000101 = 5)
    dut.ui_in.value = 0xA5
    dut.uio_in.value = 0b00000101
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    assert int(dut.uo_out.value) == 0xA5, f"Load failed: expected 0xA5, got {hex(int(dut.uo_out.value))}"

    # 3. Up Count Test (load=0, up_down=1, en=1 -> uio = 0b00000110 = 6)
    dut.uio_in.value = 0b00000110
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    assert int(dut.uo_out.value) == 0xA6, f"Up count failed: expected 0xA6, got {hex(int(dut.uo_out.value))}"

    # 4. Down Count Test (load=0, up_down=0, en=1 -> uio = 0b00000100 = 4)
    dut.uio_in.value = 0b00000100
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    assert int(dut.uo_out.value) == 0xA5, f"Down count failed: expected 0xA5, got {hex(int(dut.uo_out.value))}"

    # 5. Hold Mode Test (en=0 -> uio = 0)
    dut.uio_in.value = 0b00000000
    await ClockCycles(dut.clk, 2)
    await FallingEdge(dut.clk)
    assert int(dut.uo_out.value) == 0xA5, f"Hold failed: expected 0xA5, got {hex(int(dut.uo_out.value))}"

    # 6. Priority Test (load=1, up_down=1, en=1 -> uio = 0b00000111 = 7)
    dut.ui_in.value = 0x3C
    dut.uio_in.value = 0b00000111
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    assert int(dut.uo_out.value) == 0x3C, f"Priority test failed: expected 0x3C, got {hex(int(dut.uo_out.value))}"

    # 7. Asynchronous Reset Mid-Count Test
    dut.uio_in.value = 0b00000110  # Up count
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 0  # Trigger Async Reset
    await FallingEdge(dut.clk)
    assert int(dut.uo_out.value) == 0x00, f"Async reset mid-count failed: got {hex(int(dut.uo_out.value))}"

    dut._log.info("ALL CHARTER D01 TESTCASES PASSED!")
