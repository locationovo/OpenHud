# prefs/Makefile
TARGET := iphone:clang:latest:14.0
THEOS_PACKAGE_SCHEME := rootless

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = OpenHudPrefs
OpenHudPrefs_FILES = RootListController.m
OpenHudPrefs_CFLAGS = -fobjc-arc
OpenHudPrefs_FRAMEWORKS = UIKit CoreGraphics
OpenHudPrefs_LIBRARIES = applist
OpenHudPrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk
