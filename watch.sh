#!/bin/bash
set -e

watchexec -w Sources/App -e .swift -r './build.sh && browser-sync reload' &
#watchexec -w Sources/App -e .swift -r './build.sh' &
swift run server &
browser-sync start --proxy "127.0.0.1:9100"
