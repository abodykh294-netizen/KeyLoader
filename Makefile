TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = KeyLoader

KeyLoader_FILES = Tweak.xm
KeyLoader_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-error
KeyLoader_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
