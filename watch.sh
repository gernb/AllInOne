#!/bin/bash
set -e

watchexec -w Sources/App -e .swift -r './buildApp.sh && browser-sync reload' &
swift run server -p 9100 &
browser-sync start --proxy "127.0.0.1:9100"
