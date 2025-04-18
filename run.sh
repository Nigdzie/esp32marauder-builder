#!/bin/bash

set -euo pipefail
: "${IS_CUSTOM_AUTO:=false}"

echo "🔧 Running injection patch and validation..."
mkdir -p /project/output

if [[ "$IS_CUSTOM_AUTO" == "true" ]]; then
  echo "🚀 Running injection for custom auto board: $MARAUDER_BOARD"
  python3 "/project/custom_boards/${MARAUDER_BOARD}/inject.py" --all > /project/output/inject.log 2>&1

  if [[ $? -ne 0 ]]; then
    echo "❌ Injection failed. See log:"
    cat /project/output/inject.log
    exit 1
  fi
else
  echo "🧘 Skipping injection step (IS_CUSTOM_AUTO != true)"
fi

if [[ ! -f /project/platform.txt ]]; then
  echo "❌ platform.txt not found in /project"
  exit 1
fi

cp /project/platform.txt "/root/.arduino15/packages/esp32/hardware/esp32/${ESP32_VERSION}/platform.txt"

SKETCH_PATH="/project/ESP32Marauder/esp32_marauder/esp32_marauder.ino"
FQBN="esp32:esp32:$ESP32_CHIP"

echo "📦 FQBN: $FQBN"
echo "📁 Sketch: $SKETCH_PATH"
echo "⚙️  Compiling for board: $MARAUDER_BOARD"

if [[ ! -f "$SKETCH_PATH" ]]; then
  echo "❌ Sketch file not found at $SKETCH_PATH"
  echo "📂 Listing content of /project/ESP32Marauder/esp32_marauder:"
  ls -la /project/ESP32Marauder/esp32_marauder || echo "(folder missing)"
  echo "📂 PWD: $(pwd)"
  exit 1
else
  echo "✅ Sketch file found"
fi

arduino-cli compile \
  --fqbn "$FQBN" \
  --output-dir /project/output \
  "$SKETCH_PATH"

VERSION=$(grep '#define MARAUDER_VERSION' /project/ESP32Marauder/esp32_marauder/configs.h | cut -d'"' -f2)
BOARD_TAG="$MARAUDER_BOARD"
FINAL_PREFIX="${BOARD_TAG}_${VERSION}"
BIN_PATH="/project/output"

mv "$BIN_PATH/esp32_marauder.ino.bin" "$BIN_PATH/ESP32_Marauder_${FINAL_PREFIX}.bin"
mv "$BIN_PATH/esp32_marauder.ino.bootloader.bin" "$BIN_PATH/bootloader.bin"
mv "$BIN_PATH/esp32_marauder.ino.partitions.bin" "$BIN_PATH/partitions.bin"

echo "✅ Firmware output:"
ls -1 "$BIN_PATH"/ESP32_*"${FINAL_PREFIX}.bin"

echo "$VERSION" > /project/output/version.txt

BOOT_APP0_SRC="/root/.arduino15/packages/esp32/hardware/esp32/${ESP32_VERSION}/tools/partitions/boot_app0.bin"
if [[ -f "$BOOT_APP0_SRC" ]]; then
  cp "$BOOT_APP0_SRC" "$BIN_PATH/boot_app0.bin"
  echo "✅ boot_app0.bin copied as: boot_app0.bin"
else
  echo "⚠️ boot_app0.bin not found at expected location"
fi

if [[ "$IS_CUSTOM_AUTO" == "true" ]]; then
  echo "🔍 Validating injected source files..."
  python3 "/project/custom_boards/${MARAUDER_BOARD}/inject.py" --validate || {
    echo "❌ Injection validation failed!" >&2
    exit 1
  }
fi

if [[ -f "/project/output/inject.log" ]]; then
  echo "🪵 Injection log:"
  cat /project/output/inject.log
else
  echo "⚠️ inject.log not found inside container."
fi

echo "🧹 Cleaning up extra files..."
rm -f "$BIN_PATH"/*.elf "$BIN_PATH"/*.map "$BIN_PATH"/inject.log
