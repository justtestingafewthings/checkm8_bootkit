UNAME := $(shell uname)

CC = clang

CFLAGS  = -O3 -D_GNU_SOURCE
CFLAGS += -Ililirecovery
CFLAGS += $(shell pkg-config --cflags libusb-1.0)
CFLAGS += $(shell pkg-config --cflags jansson)

LDFLAGS  = $(shell pkg-config --libs libusb-1.0)
LDFLAGS += $(shell pkg-config --libs jansson)

BUILD_PATH = build

SOURCES = \
	src/main.c \
	src/batch.c \
	src/utils.c \
	lilirecovery/lilirecovery_linux.c \
	src/libbootkit/log.c \
	src/libbootkit/boot.c \
	src/libbootkit/ops.c \
	src/libbootkit/dfu.c \
	src/libbootkit/protocol.c

RESULT = $(BUILD_PATH)/checkm8_bootkit

# Payload headers are pre-built and committed.
# Only regenerate them explicitly with "make payloads" (requires ARM cross-compiler + vmacho).
PAYLOAD_H         = src/libbootkit/payload.h
PAYLOAD_WATCH_H   = src/libbootkit/payload_watch.h
PAYLOAD_OBJ       = $(BUILD_PATH)/payload.o
PAYLOAD_WATCH_OBJ = $(BUILD_PATH)/payload_watch.o
PAYLOAD_SRC       = src/libbootkit/payloads/payload.S
PAYLOAD_WATCH_SRC = src/libbootkit/payloads/payload_watch.S

ARM_CC = clang -target armv7-apple-ios6.0
VMACHO = vmacho

DIR_HELPER = mkdir -p $(@D)

.PHONY: all payloads clean clean-headers

all: $(RESULT)
	@echo "%%%%% done building"

$(RESULT): $(SOURCES)
	@echo "\tbuilding checkm8_bootkit"
	@$(DIR_HELPER)
	@$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@

payloads: $(PAYLOAD_H) $(PAYLOAD_WATCH_H)

$(PAYLOAD_OBJ): $(PAYLOAD_SRC)
	@echo "\tbuilding boot payload obj"
	@$(DIR_HELPER)
	@$(ARM_CC) -c $< -o $@

$(PAYLOAD_H): $(PAYLOAD_OBJ)
	@echo "\tbuilding boot payload header"
	@$(VMACHO) -f -C payload $< $@

$(PAYLOAD_WATCH_OBJ): $(PAYLOAD_WATCH_SRC)
	@echo "\tbuilding watch boot payload obj"
	@$(DIR_HELPER)
	@$(ARM_CC) -c $< -o $@

$(PAYLOAD_WATCH_H): $(PAYLOAD_WATCH_OBJ)
	@echo "\tbuilding watch boot payload header"
	@$(VMACHO) -f -C payload_watch $< $@

clean:
	@rm -rf $(BUILD_PATH)
	@echo "%%%%% done cleaning"

clean-headers:
	@rm -f $(PAYLOAD_H) $(PAYLOAD_WATCH_H)
	@echo "%%%%% done cleaning headers"
