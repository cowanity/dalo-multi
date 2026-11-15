VERSION ?= 1.3.0

.PHONY: macos-release clean

macos-release:
	VERSION=$(VERSION) BUILD_NUMBER=130 RELEASE_LABEL=v1.3 ./packaging/macos/build-dmgs.sh

clean:
	rm -rf .build dist
