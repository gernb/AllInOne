CONFIG = debug
APPSDK = 6.1-RELEASE-wasm32-unknown-wasi
CONTAINERSDK = swift-6.1.2-RELEASE_static-linux-0.0.1
REPOSITORY = registry:5000
TAG = app-server
DEVPORT = 9100

container: CONFIG = release
CONFIGURATION = $(CONFIG)

.PHONY: help
help:
	@echo "Possible targets: apps, appbasic, server, container"

apps: appbasic

appbasic:
	swift package --swift-sdk ${APPSDK} --allow-writing-to-package-directory js --use-cdn --product app-basic -c ${CONFIGURATION} --output public/app-basic

sync:
	browser-sync reload

server:
	swift build -c ${CONFIGURATION} --product server

run:
	swift run -c ${CONFIGURATION} server -p ${DEVPORT} 

watch:
	watchexec -w Sources/AppBasic -e .swift -r 'make apps sync' & make run

container: apps
	swift build --swift-sdk ${CONTAINERSDK} --triple aarch64-swift-linux-musl -c ${CONFIGURATION} --product server
	sudo docker build -t ${REPOSITORY}/${TAG} .
	sudo docker push ${REPOSITORY}/${TAG}
# containertool doesn't appear to work well on linux
# #swift package --swift-sdk $SDK -c $CONFIGURATION build-container-image --allow-insecure-http both --repository ${REPOSITORY}/${TAG} --from swift:slim --product server
# swift run containertool --allow-insecure-http both --from swift:slim --resources ./public --repository ${REPOSITORY}/${TAG} ./.build/aarch64-swift-linux-musl/${CONFIGURATION}/server

clean:
	swift package clean

