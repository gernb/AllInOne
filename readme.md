### All-In-One

A proof-of-concept for demonstrating that Swift can be used to write mobile applications for all platforms (iOS, Android, etc) and distributed as a web application. This project mostly serves to prove-out that SwiftWASM can be used to leverage knowledge of Swift and SwiftUI development while still benefitting from platform independence. There are plenty of areas left unexplored and work to be done to make this more resuable.

## Overview

This project can be built on any platform that has a Swift compiler (including macOS and Linux) and was primarily developed on a RaspberryPi. While Xcode can be used to build and run the web server portion of the project, SwiftWASM (used by the application portion) does require the use of an alternate SDK and is easier to setup and use from the command line. Follow the links below to install Swift, the necessary SDKs, and additional optional tools for development.

After the project is built, it can be deployed to a container environment (like Docker or macOS's container) and this container does not need the swift development tools.

The project is structured as a server, which is a standard web server written in Swift using Hummingbird, which acts as both the delivery mechanism for the app, as well as the API server for the app's file browser capability. There are 2 different app implementations: a basic implementation that uses a minimumal dependency set to show off the functionality but with no fancy UI styling, and a "fancy" version that uses the Framework7 component library to demonstrate the functionality can be presented as nearly native-looking application.

## Demo

Here is a short demo of the app being served from a RaspberryPi server and running in an iPhone simulator.

![Demonstration screen recording](Demo.gif)

## Building

The easiest way to build this project is to use the Makefile to build, in turn, the server and each of the apps.

Once the requisite software is installed on your dev machine (Swift compiler and SDKs), use:
```shell
make server
make apps
make run
```
This will build the server and then each of the apps and then run the server on the local machine.

The project can be built into a deployable container with:
```shell
make container
```

Notes:\
https://www.swift.org/install/ <br>
https://book.swiftwasm.org/getting-started/setup.html

https://framework7.io/ <br>
https://github.com/watchexec/watchexec <br>
https://browsersync.io/docs

## Attributions

Images used by the "basic" version of the app are from FlatIcon <br>
[Folder icons created by Freepik - Flaticon](https://www.flaticon.com/free-icons/folder) <br>
[Download icons created by Freepik - Flaticon](https://www.flaticon.com/free-icons/download) <br>
[Fire icons created by Freepik - Flaticon](https://www.flaticon.com/free-icons/fire) <br>
[Back icons created by Freepik - Flaticon](https://www.flaticon.com/free-icons/back) <br>
[Synchronization icons created by Freepik - Flaticon](https://www.flaticon.com/free-icons/synchronization) <br>
