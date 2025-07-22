CONFIGURATION=${1:-debug}

set -ex
swift build --product server -c $CONFIGURATION

