# daemon/Makefile
TARGET := iphone:clang:latest:14.0
THEOS_PACKAGE_SCHEME := rootless

include $(THEOS)/makefiles/common.mk

TOOL_NAME = OpenHudDaemon
OpenHudDaemon_FILES = main.m
OpenHudDaemon_CFLAGS = -fobjc-arc
OpenHudDaemon_FRAMEWORKS = Foundation CoreFoundation
OpenHudDaemon_INSTALL_PATH = /usr/libexec

include $(THEOS_MAKE_PATH)/tool.mk
