# tweak/Makefile
TARGET := iphone:clang:latest:14.0
THEOS_PACKAGE_SCHEME := rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OpenHud
OpenHud_FILES = Tweak.m
OpenHud_CFLAGS = -fobjc-arc
OpenHud_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

include $(THEOS_MAKE_PATH)/tweak.mk
