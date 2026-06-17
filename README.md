# SVX-Link English Australian TTS Audio Files

Audio files for SVX-Link for English Australian language support.

## Overview
The SvxLink Server, often just called SvxLink, is a general purpose voice services system, which when connected to a transceiver, can act as both an advanced repeater system and can also operate on a simplex channel. One could call it a radio operating system.
This repository contains audio files specifically designed for SVX-Link, providing English Australian (en_AU) language support.

## Repository Contents

This repository is organized into multiple branches, each containing audio files generated using different TTS engines and voices:

## Branches

### 🎤 Google-Female-1
- **TTS Engine**: Google Cloud Text-to-Speech
- **Voice Type**: Female Plain
- **Language**: English (Australian)
- Contains audio files generated using Google's female voice for Australian English

### 🎤 Google-Male-1
- **TTS Engine**: Google Cloud Text-to-Speech
- **Voice Type**: Male News-G
- **Language**: English (Australian)
- Contains audio files generated using Google's male voice for Australian English
  
### 🎤 Google-Female-2
- **TTS Engine**: Google Cloud Text-to-Speech
- **Voice Type**: Female Neural2-C
- **Language**: English (Australian)
- Contains audio files generated using Google's female voice for Australian English

### 🎤 Google-Male-2
- **TTS Engine**: Google Cloud Text-to-Speech
- **Voice Type**: Male Neural2-D
- **Language**: English (Australian)
- Contains audio files generated using Google's male voice for Australian English

### 🎤 Google-Female-3
- **TTS Engine**: Google Cloud Text-to-Speech
- **Voice Type**: Female News-F
- **Language**: English (Australian)
- Contains audio files generated using Google's female voice for Australian English

### 🎤 Google-Male-3
- **TTS Engine**: Google Cloud Text-to-Speech
- **Voice Type**: Male Standard-B
- **Language**: English (Australian)
- Contains audio files generated using Google's male voice for Australian English

### 📌 main
- **Description**: Primary branch
- The main reference branch of text files for the repository

## Features

- ✅ Multiple voice options (Male and Female)
- ✅ High-quality Google Cloud TTS audio
- ✅ Australian English language support
- ✅ Optimized for SVX-Link integration
- ✅ Licensed under GNU General Public License v2.0

## Getting Started

### 1. Clone the Repository
   ```bash
git clone https://github.com/vk5trm/en_AU-VK5TRM.git)
   ```
### 2. Then move the files to the SVXLink sounds directory
   ```bash
sudo mv en_AU-VK5TRM /usr/share/svxlink/sounds
   ```

### 3. Switch to your preferred branch:
You will need to go though each of the voices so that they are known to your system before using my [svx-cmd](https://github.com/vk5trm/svxlink-cmd) script
 ```bash
cd /usr/share/svxlink/sounds/en_AU-VK5TRM
```
   For Google Female voice number 1
  ```bash
git checkout Google-Female-1
  ```
   For Google Male voice number 1
  ```bash
git checkout Google-Male-1
  ```
   For Google Female voice number 2
  ```bash
git checkout Google-Female-2
  ```
   For Google Male voice number 2
  ```bash
git checkout Google-Male-2
  ```
  For Google Female voice number 3
  ```bash
git checkout Google-Female-3
  ```
   For Google Male voice number 3
  ```bash
git checkout Google-Male-3
  ```

### 4a. Integrate the audio files into your SVX-Link configuration by adding this to your repeater or simplex logic in your svxlink.conf 
 ```bash
DEFAULT_LANG=en_AU-VK5TRM
 ```
### or
      
### 4b. Create a link to the new directory by using
```bash
cd /usr/share/svxlink/sounds/
sudo ln -s /usr/share/svxlink/sounds/en_AU en_US
```
### 5. Check for updates with
```bash
cd /usr/share/svxlink/sounds/en_AU-VK5TRM
git pull
```

## License

This project is licensed under the **GNU General Public License v2.0** - see the LICENSE file for details.

This means:
- You are free to use, modify, and distribute this software
- Any derivative works must also be licensed under GPL v2.0
- You must provide source code with any distribution

## About SVX-Link

SVX-Link is a Linux-based amateur radio voice server developed for the amateur radio community. For more information about SVX-Link, visit:
- [SVX-Link Official Website](https://www.svxlink.org/)

## Support

For issues or questions regarding this repository, please open an issue on GitHub.

## Author

**Rob vk5trm** - Repository Owner

---

**Last Updated**: June 2, 2026
