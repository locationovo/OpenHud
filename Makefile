# 顶层Makefile
TARGET := iphone:clang:latest:14.0
THEOS_PACKAGE_SCHEME := rootless

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += tweak
SUBPROJECTS += daemon
SUBPROJECTS += prefs

include $(THEOS_MAKE_PATH)/aggregate.mk
