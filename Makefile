APP_NAME := OzDoro
PROJECT := $(APP_NAME).xcodeproj
SCHEME := $(APP_NAME)
DERIVED_DATA := build
APP_PATH := $(DERIVED_DATA)/Build/Products/Release/$(APP_NAME).app
INSTALL_DIR := $(HOME)/Applications
SWIFT_FORMAT := $(shell command -v swift-format 2>/dev/null || xcrun --find swift-format 2>/dev/null)

.PHONY: build build-debug run install test clean open check-localizations format format-check verify

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release -derivedDataPath $(DERIVED_DATA) -destination 'generic/platform=macOS' 'ARCHS=arm64 x86_64' ONLY_ACTIVE_ARCH=NO CODE_SIGNING_ALLOWED=NO -quiet build

build-debug:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug -derivedDataPath $(DERIVED_DATA) -destination 'generic/platform=macOS' 'ARCHS=arm64 x86_64' ONLY_ACTIVE_ARCH=NO CODE_SIGNING_ALLOWED=NO -quiet build

run: build
	open "$(APP_PATH)"

install: build
	mkdir -p "$(INSTALL_DIR)"
	ditto "$(APP_PATH)" "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "Installed to $(INSTALL_DIR)/$(APP_NAME).app"

open:
	open "$(PROJECT)"

test:
	swift test

format:
	$(SWIFT_FORMAT) format --in-place --recursive OzDoro Tests Package.swift

format-check:
	$(SWIFT_FORMAT) lint --strict --recursive OzDoro Tests Package.swift

check-localizations:
	python3 Scripts/check_localizations.py

# The full Xcode app build is performed separately on a macOS runner.
verify: format-check check-localizations test

clean:
	rm -rf "$(DERIVED_DATA)" .build
