SIM ?= icarus
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src
PROJECT_SOURCES = tt_um_d01_counter.v

ifneq ($(GATES),yes)
PROJECT_SOURCES += tb.v
endif

TOPLEVEL = tb
MODULE = test

include $(shell cocotb-config --makefiles)/makefile.sim
