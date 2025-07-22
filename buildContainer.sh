CONFIGURATION=${1:-release}
SDK=${SWIFT_SDK_ID:-swift-6.1.2-RELEASE_static-linux-0.0.1}
REPOSITORY=registry:5000

set -ex
#swift package --swift-sdk $SDK -c $CONFIGURATION build-container-image --allow-insecure-http both --repository ${REPOSITORY}/app-server --from swift:slim --product server
swift build --swift-sdk $SDK -c $CONFIGURATION --product server
swift run containertool --allow-insecure-http both --from swift:slim --resources ./public --repository ${REPOSITORY}/app-server ./.build/aarch64-swift-linux-musl/${CONFIGURATION}/server

