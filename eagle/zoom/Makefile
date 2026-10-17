# Builds eagle-zoom.so against the installed Hyprland headers (/usr/include/hyprland).
# The plugin only loads into the exact Hyprland commit it was built against;
# rerun install.sh after every Hyprland update.
CXXFLAGS ?= -O2
CXXFLAGS += -shared -fPIC -std=c++26 -Wall
# -z now: resolve every symbol at dlopen so a bad build fails inside
# `hyprctl plugin load` with a readable error instead of aborting Hyprland
# on first use. --no-gnu-unique: the Hyprland plugin convention; GNU-unique
# symbols pin a dlopened library and break unload.
LDFLAGS  += -Wl,-z,now --no-gnu-unique
INCLUDES  = $(shell pkg-config --cflags hyprland pixman-1 libdrm pangocairo libinput libudev wayland-server xkbcommon lua-5.5)
BUILD    ?= build
TARGET    = $(BUILD)/eagle-zoom.so

all: $(TARGET)

$(TARGET): main.cpp
	mkdir -p $(BUILD)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(INCLUDES) $< -o $@

clean:
	rm -rf $(BUILD)

.PHONY: all clean
