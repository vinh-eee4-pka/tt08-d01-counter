import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

@cocotb.test()
async def test_counter(dut):
    dut._log.info("Start 8-bit Universal Counter Test")

    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)
    await Timer(1, units="ns")

    # TC_01: Reset
    assert int(dut.uo_out.value) == 0, f"Reset failed: expected 0, got {int(dut.uo_out.value)}"

    # TC_02: Parallel Load (d_in = 0xA5)
    dut.uio_in.value = 0xA5
    dut.ui_in.value = 0b00000101  # load = 1, en = 1
    await ClockCycles(dut.clk, 1)
    await Timer(1, units="ns")
    assert int(dut.uo_out.value) == 0xA5, f"Load failed: expected 0xA5, got {int(dut.uo_out.value)}"

    # TC_03: Up Count
    dut.ui_in.value = 0b00000001  # load = 0, up_down = 1, en = 1
    await ClockCycles(dut.clk, 1)
    await Timer(1, units="ns")
    assert int(dut.uo_out.value) == 0xA6, f"Up count failed: expected 0xA6, got {int(dut.uo_out.value)}"

    # TC_04: Down Count
    dut.ui_in.value = 0b00000000  # load = 0, up_down = 0, en = 1
    await ClockCycles(dut.clk, 1)
    await Timer(1, units="ns")
    assert int(dut.uo_out.value) == 0xA5, f"Down count failed: expected 0xA5, got {int(dut.uo_out.value)}"

    # TC_05: Hold Mode
    dut.ui_in.value = 0b00000000  # en = 0
    await ClockCycles(dut.clk, 2)
    await Timer(1, units="ns")
    assert int(dut.uo_out.value) == 0xA5, f"Hold failed: expected 0xA5, got {int(dut.uo_out.value)}"

    dut._log.info("All 8-bit Counter Testcases Passed!")
