.PHONY: generate build test lint format clean open

generate:
	xcodegen generate

open: generate
	open Ghost.xcodeproj

build: generate
	xcodebuild -project Ghost.xcodeproj -scheme Ghost \
		-destination 'generic/platform=iOS Simulator' build | xcpretty || true

test: generate
	xcodebuild -project Ghost.xcodeproj -scheme Ghost \
		-destination 'platform=iOS Simulator,name=iPhone 16' test | xcpretty || true

lint:
	swiftlint

format:
	swiftformat .

clean:
	rm -rf Ghost.xcodeproj DerivedData .build
