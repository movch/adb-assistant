## ADB Assistant

![](screenshot.png)

**ADB Assistant** is a macOS GUI wrapper for ADB (Android Device Bridge) comand line tool. It allows you to communicate and perform basic actions with Android device from your computer.

Currently it provides the ability to:

* **Choose a device** from the list of connected devices;
* **Reboot the device** to:
  * System
  * Recovery
  * Bootloader
* **Take screenshot** from the device and save it to your computer;
* **Install an APK to device** by a simple drag'n'drop.

## Installation

* Grab latest binary from the Releases page and unpack it to the Applications folder on your Mac;
* [Download latest Android Platform Tools](https://developer.android.com/studio/releases/platform-tools) from the official site (or install them via Homebrew: `brew cask install android-sdk`);
* Run application, and specify the path to platform tools (if you're using Homebrew it will be `/usr/local/share/android-sdk/platform-tools`).

## Usage

* Activate the developer mode on your device (tap 5-7 times on build number in About section in Settings), navigate to Developer options and enable USB debugging;
* Once you have connected your device, the application should automatically detect it and show you the available actions.

## Build

The application has no external dependencies, so just clone and build it with latest XCode.

## Credits

The project was developed by Michail Ovchinnikov.

Icons by [Icons8](https://icons8.com).

## License

The project is distributed under MIT License.