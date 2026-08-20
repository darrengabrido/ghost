.PHONY: generate build run test lint format clean open

# Override with: make run SIMULATOR='iPhone 17 Pro'
SIMULATOR ?= iPhone 17 Pro Max

generate:
	xcodegen generate

open: generate
	open Ghost.xcodeproj

build: generate
	xcodebuild -project Ghost.xcodeproj -scheme Ghost \
		-destination 'generic/platform=iOS Simulator' build | xcpretty || true

run: generate
	@scripts/run-simulator.sh "$(SIMULATOR)"

test: generate
	xcodebuild -project Ghost.xcodeproj -scheme Ghost \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR)' test | xcpretty || true

lint:
	swiftlint

format:
	swiftformat .

clean:
	rm -rf Ghost.xcodeproj DerivedData .build
