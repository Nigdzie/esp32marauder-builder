<p align="center">
  <a href="https://github.com/Nigdzie/esp32marauder-builder/actions">
    <img alt="Build Status" src="https://github.com/Nigdzie/esp32marauder-builder/actions/workflows/build.yml/badge.svg">
  </a>
  <a href="https://hits.sh/github.com/Nigdzie/esp32marauder-builder/">
    <img alt="Hits" src="https://hits.sh/github.com/Nigdzie/esp32marauder-builder.svg">
  </a>
  <a href="https://github.com/Nigdzie/esp32marauder-builder/issues">
    <img alt="Issues" src="https://img.shields.io/github/issues/Nigdzie/esp32marauder-builder">
  </a>
  <a href="https://github.com/Nigdzie/esp32marauder-builder/pulls">
    <img alt="Pull Requests" src="https://img.shields.io/github/issues-pr/Nigdzie/esp32marauder-builder">
  </a>
  <a href="https://github.com/Nigdzie/esp32marauder-builder/blob/main/LICENSE">
    <img alt="License" src="https://img.shields.io/github/license/Nigdzie/esp32marauder-builder">
  </a>
  <a href="https://github.com/Nigdzie/esp32marauder-builder">
    <img alt="Repo Size" src="https://img.shields.io/github/repo-size/Nigdzie/esp32marauder-builder">
  </a>
  <a href="https://github.com/Nigdzie/esp32marauder-builder/commits/main">
    <img alt="Last Commit" src="https://img.shields.io/github/last-commit/Nigdzie/esp32marauder-builder">
  </a>
</p>

---
# 🛠 ESP32Marauder Docker Builder

This project provides a convenient Docker-based build system for compiling firmware from the [ESP32Marauder](https://github.com/justcallmekoko/ESP32Marauder) repository.

It supports building only custom boards defined locally.

---

## 🔧 Usage

1. Clone this repository:
   ```bash
   git clone https://github.com/Nigdzie/esp32marauder_builder.git
   cd esp32marauder_builder
   ```

2. Start the build:
   ```bash
   ./build.sh
   ```

   Or build specific board directly:
   ```bash
   ./build.sh board=BPMCIRCUITS_FEBERIS
   ```

3. Firmware files will be saved in the `output/` folder.

---

## 📁 Adding a New Custom Board

To add support for your custom board, create a new folder in the `custom_boards/` directory. For example:
```
custom_boards/BPMCIRCUITS_MYBOARD/
```

Your board folder should contain:

| File              | Description |
|-------------------|-------------|
| `chip.txt`        | One line file with your chip: `esp32`, `esp32s2`, `esp32s3`, or `esp32c3` |
| `platform.txt`    | Platform overrides (copied into Arduino platform path) |
| `libs.txt`        | List of Arduino library names (one per line) |
| `libs_git.txt`    | List of external Git libraries in `URL@VERSION` format |
| `inject.py`       | Python script to inject `configs.h` and `WiFiScan.cpp` patches |
| `info.txt`        | Optional metadata file shown for documentation purposes |

### 📘 Example info.txt

```
Info: BPMCIRCUITS_FEBERIS_PRO
Project URL: https://github.com/bpmcircuits/ESP32Marauder_FEBERIS
Description: Supporting as well https://github.com/bpmcircuits/ESP32Marauder_NetNinja
```

### 📂 Custom Files & Libraries Support

Each custom board folder (`custom_boards/<BOARD_NAME>/`) can optionally include the following directories:

- `Files/`  
  All contents will be **recursively copied** into:
  ```
  /project/ESP32Marauder/esp32_marauder/
  ```
  This is useful for adding or replacing `.cpp`, `.h`, image assets, or other source files directly in the firmware.

- `Libs/`  
  All contents will be **recursively copied** into:
  ```
  /root/Arduino/libraries/
  ```
  This allows including local or patched Arduino libraries that are not available via the Arduino Library Manager or `libs_git.txt`.

These folders are automatically handled during the Docker build process and require no manual steps.

#### ✅ Example Folder Structure

```
custom_boards/
└── MYBOARD/
    ├── chip.txt
    ├── libs.txt
    ├── libs_git.txt
    ├── inject.py
    ├── platform.txt
    ├── info.txt
    ├── Files/
    │   └── CustomFeature.cpp
    └── Libs/
        └── MySensorLib/
            ├── MySensorLib.h
            └── MySensorLib.cpp
```

All files inside `Files/` and `Libs/` will be available to the firmware during compilation.


### 🧩 About inject.py

`inject.py` must support:
- `--patch`: patch source files
- `--validate`: validate applied changes
- `--all`: patch and validate (combined)

The script is executed automatically during the build process.

### 📦 About Library Files

- `libs.txt`:
  - Add standard Arduino libraries like:
    ```
    LinkedList
    ArduinoJson
    ```

- `libs_git.txt`:
  - External Git repositories (auto-cloned and checked out to given version):
    ```
    https://github.com/me-no-dev/AsyncTCP.git@master
    https://github.com/me-no-dev/ESPAsyncWebServer.git@master
    ```

---

## 📦 Firmware Output

Firmware will be saved as:
```
ESP32_Marauder_<BOARD>_<VERSION>.bin
```

Auxiliary files like `bootloader.bin`, `partitions.bin`, and `boot_app0.bin` will also be exported if found.

---

## 🧹 Cleaning

To clean build files:
```bash
./build.sh clean
```

---

## ✅ Tested On

- Docker 28.0.4+
- Compose v2 and `docker-compose`
- Works with ESP32-WROOM, ESP32-S3, and ESP32-S2

---


## 📋 Sample successful build log

```
./build.sh
🔍 Checking Docker Compose compatibility...
✅ Docker Compose is available
📦 Available custom boards:
1) BPMCIRCUITS_FEBERIS
2) BPMCIRCUITS_FEBERIS_PRO
🔧 Select target board: 1
✅ Selected: BPMCIRCUITS_FEBERIS
🔎 Detected chip from chip.txt: esp32
📦 Board: BPMCIRCUITS_FEBERIS
🔧 Chip family: esp32
🪡 Core version: 2.0.10
🔹 Custom auto mode: true
📝 Board Info:
Info: BPMCIRCUITS_FEBERIS
Project URL: https://github.com/bpmcircuits/ESP32Marauder_FEBERIS
Description:


Compose can now delegate builds to bake for better performance.
 To do so, set COMPOSE_BAKE=true.
 => [marauder-builder internal] load build definition from Dockerfile                                                                                                              0.0ss => => transferring dockerfile: 2.55kB                                                                                                                                             0.0ss => [marauder-builder internal] load metadata for docker.io/library/ubuntu:22.04                                                                                                  11.6s3 => [marauder-builder internal] load .dockerignore                                                                                                                                 0.0ss => => transferring context: 2B                                                                                                                                                    0.0ss => [marauder-builder internal] load build context                                                                                                                                 0.1s3 => => transferring context: 191.21kB                                                                                                                                              0.0ss => [marauder-builder  1/17] FROM docker.io/library/ubuntu:22.04@sha256:d80997daaa3811b175119350d84305e1ec9129e1799bba0bd1e3120da3ff52c3                                           1.7ss => => resolve docker.io/library/ubuntu:22.04@sha256:d80997daaa3811b175119350d84305e1ec9129e1799bba0bd1e3120da3ff52c3                                                              0.0s3 => => sha256:d80997daaa3811b175119350d84305e1ec9129e1799bba0bd1e3120da3ff52c3 6.69kB / 6.69kB                                                                                     0.0ss => => sha256:a76d0e9d99f0e91640e35824a6259c93156f0f07b7778ba05808c750e7fa6e68 424B / 424B                                                                                         0.0ss => => sha256:cc934a90cd99a939f3922f858ac8f055427300ee3ee4dfcd303c53e571d0aeab 2.30kB / 2.30kB                                                                                     0.0s3 => => sha256:30a9c22ae099393b0131322d7f50d8a9d7cd06c5e518cd27a19ac960a4d0aba3 29.53MB / 29.53MB                                                                                   0.5ss => => extracting sha256:30a9c22ae099393b0131322d7f50d8a9d7cd06c5e518cd27a19ac960a4d0aba3                                                                                          0.9ss => [marauder-builder  2/17] RUN apt-get update && apt-get install -y     curl unzip git xz-utils python3 python3-pip nano     gcc make jq sed && rm -rf /var/lib/apt/lists/*     41.3s3 => [marauder-builder  3/17] RUN curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh                                                           2.3ss => [marauder-builder  4/17] RUN arduino-cli config init &&     arduino-cli core update-index &&     arduino-cli core install esp32:esp32@2.0.10                                  50.8ss => [marauder-builder  5/17] COPY custom_boards/BPMCIRCUITS_FEBERIS/ /tmp/                                                                                                         0.1s3 => [marauder-builder  6/17] RUN grep -v '^#' /tmp/libs.txt | grep -v '^\s*$' | while read lib; do       echo "📦 Installing $lib...";       until arduino-cli lib install "$li     8.8s => [marauder-builder  7/17] RUN mkdir -p /root/Arduino/libraries && cd /root/Arduino/libraries &&     while IFS=@ read -r REPO VERSION; do         DIR=$(basename "$REPO" .git);  2.1ss => [marauder-builder  8/17] RUN pip3 install pyserial                                                                                                                             1.1s3 => [marauder-builder  9/17] RUN rm -rf /project/ESP32Marauder &&     git clone --depth=1 https://github.com/justcallmekoko/ESP32Marauder.git /project/ESP32Marauder              50.6s3 => [marauder-builder 10/17] RUN echo "🚀 Running inject.py for BPMCIRCUITS_FEBERIS";      mkdir -p /project/output &&      set -e &&      python3 /tmp/inject.py --all > /proj     0.3s => [marauder-builder 11/17] RUN if [[ -f /project/output/inject.log ]]; then       echo "🪵 Injection log:" && cat /project/output/inject.log;     else       echo "📭 No in        0.3s=> [marauder-builder 13/17] RUN echo "📂 Copying Libs to /root/Arduino/libraries/";     if [[ -d /tmp/Libs ]]; then       echo "📂 Copying Libs to /root/Arduino/libraries/"        0.3 => [marauder-builder 12/17] RUN echo "📂 Copying Files to esp32_marauder";     if [[ -d /tmp/Files ]]; then       echo "📂 Copying Files to esp32_marauder";       cp -rv /t        0.3s=> [marauder-builder 14/17] RUN mkdir -p /root/.arduino15/packages/esp32/hardware/esp32/2.0.10                                                                                    0.2s
 => [marauder-builder 13/17] RUN echo "📂 Copying Libs to /root/Arduino/libraries/";     if [[ -d /tmp/Libs ]]; then       echo "📂 Copying Libs to /root/Arduino/libraries/"        0.3s=> [marauder-builder 16/17] WORKDIR /project                                                                                                                                      0.1s
 => [marauder-builder 14/17] RUN mkdir -p /root/.arduino15/packages/esp32/hardware/esp32/2.0.10                                                                                    0.2s
 => [marauder-builder 15/17] COPY platform.txt /root/.arduino15/packages/esp32/hardware/esp32/2.0.10/platform.txt                                                                  0.1s
 => [marauder-builder 16/17] WORKDIR /project                                                                                                                                      0.1s
 => [marauder-builder 17/17] RUN if [[ -f /project/ESP32Marauder/esp32_marauder/esp32_marauder.ino ]]; then       chmod +r /project/ESP32Marauder/esp32_marauder/esp32_marauder.i  0.3s
 => [marauder-builder] exporting to image                                                                                                                                          7.8s
 => => exporting layers                                                                                                                                                            7.8s
 => => writing image sha256:c2725a1153987ee730c332b5796fec4f11640fef6f4076b6e8ee070760a459a0                                                                                       0.0s
 => => naming to docker.io/library/esp32marauder-builder-marauder-builder                                                                                                          0.0s
 => [marauder-builder] resolving provenance for metadata file                                                                                                                      0.0s
[+] Building 1/1
 ✔ marauder-builder  Built                                                                                                                                                         0.0s
[+] Running 2/2
 ✔ Network esp32marauder-builder_default  Created                                                                                                                                  0.1s
 ✔ Container esp32marauder_builder        Created                                                                                                                                  0.1s
Attaching to esp32marauder_builder
esp32marauder_builder  | 🔧 Running injection patch and validation...
esp32marauder_builder  | 🚀 Running injection for custom auto board: BPMCIRCUITS_FEBERIS
esp32marauder_builder  | 📦 FQBN: esp32:esp32:esp32
esp32marauder_builder  | 📁 Sketch: /project/ESP32Marauder/esp32_marauder/esp32_marauder.ino
esp32marauder_builder  | ⚙️  Compiling for board: BPMCIRCUITS_FEBERIS
esp32marauder_builder  | ✅ Sketch file found
esp32marauder_builder  | Sketch uses 1238569 bytes (94%) of program storage space. Maximum is 1310720 bytes.
esp32marauder_builder  | Global variables use 77700 bytes (23%) of dynamic memory, leaving 249980 bytes for local variables. Maximum is 327680 bytes.
esp32marauder_builder  | ✅ Firmware output:
esp32marauder_builder  | /project/output/ESP32_Marauder_BPMCIRCUITS_FEBERIS_v1.4.4.bin
esp32marauder_builder  | ✅ boot_app0.bin copied as: boot_app0.bin
esp32marauder_builder  | 🔍 Validating injected source files...
esp32marauder_builder  | 🔍 Validating configs.h...
esp32marauder_builder  | ✅ Injection validation passed.
esp32marauder_builder  | 🪵 Injection log:
esp32marauder_builder  | ⚙️ Patching configs.h...
esp32marauder_builder  | ✅ configs.h patched successfully.
esp32marauder_builder  | ✅ configs.h: inserted targets = True , features = True , mem_limit = True , html_limit = True
esp32marauder_builder  | ⚙️ Patching WiFiScan.cpp...
esp32marauder_builder  | ✅ Patched: sd_obj.removeFile("/Airtags_0.log");
esp32marauder_builder  | ✅ Patched: sd_obj.removeFile("/APs_0.log");
esp32marauder_builder  | ✅ Patched: sd_obj.removeFile("/SSIDs_0.log");
esp32marauder_builder  | ✅ WiFiScan.cpp patched successfully.
esp32marauder_builder  | 🔍 Validating configs.h...
esp32marauder_builder  | ✅ Injection validation passed.
esp32marauder_builder  | 🧹 Cleaning up extra files...
esp32marauder_builder exited with code 0
root@szer:~/esp32marauder-builder# ls output/
boot_app0.bin  bootloader.bin  ESP32_Marauder_BPMCIRCUITS_FEBERIS_v1.4.4.bin  partitions.bin  version.txt
```

---

## ⚠️ Typical Errors

### 🔌 Network Timeout or Docker Registry Issues

If you encounter errors like this during image build:

  ```
  [+] Building 20.2s (2/2) FINISHED                                                                                                                docker:default
 => [marauder-builder internal] load build definition from Dockerfile                                                                                      0.0s
 => => transferring dockerfile: 3.44kB                                                                                                                     0.0s
 => ERROR [marauder-builder internal] load metadata for docker.io/library/ubuntu:22.04                                                                    20.0s
------
 > [marauder-builder internal] load metadata for docker.io/library/ubuntu:22.04:
------
failed to solve: ubuntu:22.04: failed to resolve source metadata for docker.io/library/ubuntu:22.04: failed to do request: Head "https://registry-1.docker.io/v2/library/ubuntu/manifests/22.04": dial tcp: lookup registry-1.docker.io: no such host

  ```
OR

  ```
 => => extracting sha256:30a9c22ae099393b0131322d7f50d8a9d7cd06c5e518cd27a19ac960a4d0aba3                                                                0.6s
 => [marauder-builder internal] load build context                                                                                                       0.1s
 => => transferring context: 191.34kB                                                                                                                    0.0s
 => [marauder-builder  2/16] RUN apt-get update && apt-get install -y     curl unzip git xz-utils python3 python3-pip nano     gcc make jq sed && rm -  43.7s
 => [marauder-builder  3/16] RUN curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh                                 2.5s
 => ERROR [marauder-builder  4/16] RUN arduino-cli config init &&     arduino-cli core update-index &&     arduino-cli core install esp32:esp32@2.0.10  12.6s
------
 > [marauder-builder  4/16] RUN arduino-cli config init &&     arduino-cli core update-index &&     arduino-cli core install esp32:esp32@2.0.10:
0.245 Config file written to: /root/.arduino15/arduino-cli.yaml
Downloading index: library_index.tar.bz2 downloaded MiB    0.00%
Downloading index: package_index.tar.bz2 downloaded2 KiB    0.00%
1.671 Downloading missing tool builtin:ctags@5.8-arduino11...
builtin:ctags@5.8-arduino11 downloaded99 KiB    0.00%
1.769 Installing builtin:ctags@5.8-arduino11...
1.800 Skipping tool configuration....
1.800 builtin:ctags@5.8-arduino11 installed
1.800 Downloading missing tool builtin:dfu-discovery@0.1.2...
builtin:dfu-discovery@0.1.2 downloaded MiB    0.00%
1.902 Installing builtin:dfu-discovery@0.1.2...
1.950 Skipping tool configuration....
1.950 builtin:dfu-discovery@0.1.2 installed
1.950 Downloading missing tool builtin:mdns-discovery@1.0.9...
builtin:mdns-discovery@1.0.9 downloaded MiB    0.00%
2.062 Installing builtin:mdns-discovery@1.0.9...
2.107 Skipping tool configuration....
2.107 builtin:mdns-discovery@1.0.9 installed
2.107 Downloading missing tool builtin:serial-discovery@1.4.1...
builtin:serial-discovery@1.4.1 downloaded MiB    0.00%
2.180 Installing builtin:serial-discovery@1.4.1...
2.222 Skipping tool configuration....
2.222 builtin:serial-discovery@1.4.1 installed
2.222 Downloading missing tool builtin:serial-monitor@0.15.0...
builtin:serial-monitor@0.15.0 downloaded MiB    0.00%
2.325 Installing builtin:serial-monitor@0.15.0...
2.354 Skipping tool configuration....
2.354 builtin:serial-monitor@0.15.0 installed
12.50 Downloading index: package_index.tar.bz2 Get "https://downloads.arduino.cc/packages/package_index.tar.bz2": dial tcp: lookup downloads.arduino.cc on 192                          .168.0.1:53: read udp 172.17.0.6:58490->192.168.0.1:53: i/o timeout
12.50 Some indexes could not be updated.
------
failed to solve: process "/bin/bash -c arduino-cli config init &&     arduino-cli core update-index &&     arduino-cli core install esp32:esp32@${ESP32_VERSIO                          N}" did not complete successfully: exit code: 1

  ```

This usually means your system cannot resolve Docker Hub domains (DNS issue) or has no internet access from Docker.

#### ✅ Suggested Fixes:
- Ensure your machine has working DNS (e.g., try using `1.1.1.1` or `8.8.8.8`)
- Restart Docker: `sudo systemctl restart docker`
- Clean up Docker cache and retry:
  ```bash
  ./build.sh clean
  docker builder prune --all
  ./build.sh
  ```
