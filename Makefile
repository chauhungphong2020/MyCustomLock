export THEOS = $(HOME)/theos
ARCHS = arm64
TARGET := iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MyCustomLock
MyCustomLock_FILES = Tweak.x
MyCustomLock_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS)/makefiles/tweak.mk
