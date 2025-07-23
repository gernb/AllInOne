CONFIGURATION=${1:-release}
SDK=${SWIFT_SDK_ID:-swift-6.1.2-RELEASE_static-linux-0.0.1}
REPOSITORY=registry:5000
TAG=app-server

set -ex
./buildApp.sh $CONFIGURATION
swift build --swift-sdk $SDK --triple aarch64-swift-linux-musl -c $CONFIGURATION --product server

sudo docker build -t ${REPOSITORY}/${TAG} .
sudo docker push ${REPOSITORY}/${TAG}

# containertool doesn't appear to work well on linux
# #swift package --swift-sdk $SDK -c $CONFIGURATION build-container-image --allow-insecure-http both --repository ${REPOSITORY}/${TAG} --from swift:slim --product server
# swift run containertool --allow-insecure-http both --from swift:slim --resources ./public --repository ${REPOSITORY}/${TAG} ./.build/aarch64-swift-linux-musl/${CONFIGURATION}/server

