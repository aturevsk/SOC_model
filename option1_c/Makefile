# Makefile for SOC LSTM inference model
#
# Targets:
#   make          — build for host (x86/ARM Mac, Linux) with gcc -O2
#   make arm      — cross-compile for Cortex-M7 (STM32F746G-Discovery)
#   make clean    — remove build artifacts

# ---- Toolchains ----
HOST_CC    = gcc
ARM_CC     = arm-none-eabi-gcc

# ---- Source files ----
SRCS       = soc_model.c main_test.c
HEADERS    = soc_model.h soc_model_weights.h

# ---- Host build ----
HOST_BIN   = soc_test
HOST_CFLAGS = -std=c99 -O2 -Wall -Wextra -Wpedantic -lm

# ---- ARM Cortex-M7 build ----
ARM_BIN    = soc_test_arm.elf
ARM_CFLAGS = -std=c99 -Os \
             -mcpu=cortex-m7 \
             -mthumb \
             -mfpu=fpv5-sp-d16 \
             -mfloat-abi=hard \
             -DUSE_CMSIS_DSP=1 \
             -Wall -Wextra \
             -ffunction-sections -fdata-sections \
             --specs=nosys.specs \
             -lm

# ---- Targets ----

.PHONY: all arm clean

all: $(HOST_BIN)

$(HOST_BIN): $(SRCS) $(HEADERS)
	$(HOST_CC) $(HOST_CFLAGS) -o $@ $(SRCS)

arm: $(ARM_BIN)

$(ARM_BIN): $(SRCS) $(HEADERS)
	$(ARM_CC) $(ARM_CFLAGS) -o $@ $(SRCS)

clean:
	rm -f $(HOST_BIN) $(ARM_BIN)
