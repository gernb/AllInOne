CONFIGURATION=${1:-debug}
SDK=${SWIFT_SDK_ID:-6.1-RELEASE-wasm32-unknown-wasi}

set -ex
swift package --allow-writing-to-package-directory generate-css --output public/css/elementary.css
swift package --swift-sdk $SDK --allow-writing-to-package-directory js --use-cdn --product app -c $CONFIGURATION --output public/app
browser-sync reload
