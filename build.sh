#!/usr/bin/env bash

set -e

if [[ "$1" == "clean" ]]; then
  echo "🧹 Cleaning output/ folder and removing Docker build cache..."
  rm -rf output/*
  docker-compose down || docker compose down || true
  docker builder prune --all -f
  docker image prune --all --force
  exit 0
fi

# --- Check Docker Compose version compatibility ---
echo "🔍 Checking Docker Compose compatibility..."

if ! docker compose version &>/dev/null; then
  if command -v docker-compose &>/dev/null; then
    echo "⚠️ Your system uses legacy 'docker-compose'."
    echo "💡 You can rename 'docker compose' to 'docker-compose' in this script."
    echo "💡 Or upgrade Docker to use modern 'docker compose'."
    echo "❌ Aborting for now."
    exit 1
  else
    echo "❌ Neither 'docker compose' nor 'docker-compose' is available."
    echo "📦 Please install Docker Compose: https://docs.docker.com/compose/"
    exit 1
  fi
else
  echo "✅ Docker Compose is available"
fi

ESP32_VERSION="${ESP32_VERSION:-2.0.10}"
CUSTOM_DIR="./custom_boards"
custom_boards=()
CUSTOM_IDF=""
CUSTOM_IDF_DIR=""
CUSTOM_IDF_BRANCH=""

# Parse optional arguments
for arg in "$@"; do
  case $arg in
    board=*)
      input_board="${arg#board=}"
      ;;
    custom-idf=*)
      CUSTOM_IDF="${arg#custom-idf=}"
      ;;
    custom-idf-dir=*)
      CUSTOM_IDF_DIR="${arg#custom-idf-dir=}"
      ;;
    custom-idf-branch=*)
      CUSTOM_IDF_BRANCH="${arg#custom-idf-branch=}"
      ;;
  esac
done

# 📦 List available custom boards
echo "📦 Available custom boards:"
if [[ ! -d "$CUSTOM_DIR" ]]; then
  echo "❌ Directory $CUSTOM_DIR not found!"
  exit 1
fi

while IFS= read -r -d '' dir; do
  custom_boards+=("$(basename "$dir")")
done < <(find "$CUSTOM_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)


if [[ ${#custom_boards[@]} -eq 0 ]]; then
  echo "❌ No custom boards found in $CUSTOM_DIR"
  exit 1
fi

# --- Handle board from argument or interactive selection ---
if [[ -n "$input_board" ]]; then
  if [[ " ${custom_boards[*]} " =~ " $input_board " ]]; then
    MARAUDER_BOARD="$input_board"
    echo "✅ Board from argument: $MARAUDER_BOARD"
  else
    echo "❌ Provided board '$input_board' not found in $CUSTOM_DIR"
    exit 1
  fi
else
  PS3="🔧 Select target board: "
  select selected_custom in "${custom_boards[@]}"; do
    if [[ -n "$selected_custom" ]]; then
      MARAUDER_BOARD="$selected_custom"
      echo "✅ Selected: $MARAUDER_BOARD"
      break
    else
      echo "❌ Invalid choice"
    fi
  done
fi

# 🤖 Detect chip type
CHIP_FILE="$CUSTOM_DIR/$MARAUDER_BOARD/chip.txt"
manual_select=false

if [[ -f "$CHIP_FILE" ]]; then
  chip_value=$(<"$CHIP_FILE")

  case "$chip_value" in
    d32 | m5stick-c )
      ESP32_CHIP="esp32"
      FQBN="esp32:esp32:$chip_value"
      echo "🔎 Detected chip alias: $chip_value → $FQBN"
      ;;
    esp32 | esp32s2 | esp32s3 | esp32c3 )
      ESP32_CHIP="$chip_value"
      FQBN="esp32:esp32:$ESP32_CHIP"
      echo "🔎 Detected chip from chip.txt: $ESP32_CHIP"
      ;;
    esp32:*:* )
      FQBN="$chip_value"
      ESP32_CHIP="custom"
      echo "🔎 Detected full FQBN from chip.txt: $FQBN"
      ;;
    * )
      echo "⚠️ Invalid chip value in chip.txt: '$chip_value'"
      manual_select=true
      ;;
  esac

else
  echo "📬 chip.txt not found in $CHIP_FILE"
  manual_select=true
fi

if [[ "$manual_select" == true ]]; then
  echo "🔹 Select chip family manually:"
  chips=("esp32" "esp32s2" "esp32s3" "esp32c3")
  select chip in "${chips[@]}"; do
    if [[ -n "$chip" ]]; then
      ESP32_CHIP="$chip"
      FQBN="esp32:esp32:$ESP32_CHIP"
      break
    else
      echo "❌ Invalid chip"
    fi
  done
fi

# 🗒️ Final summary
echo "📦 Board: $MARAUDER_BOARD"
echo "🔧 Chip family: $ESP32_CHIP"
echo "🪡 Core version: $ESP32_VERSION"
if [[ -n "$CUSTOM_IDF" ]]; then
  echo "🔗 Custom core: $CUSTOM_IDF"
  echo "📂 Core dir: $CUSTOM_IDF_DIR"
  if [[ -n "$CUSTOM_IDF_BRANCH" ]]; then
    echo "🌿 Core branch: $CUSTOM_IDF_BRANCH"
  fi
fi

# 📃 Show board info.txt if present
INFO_FILE="$CUSTOM_DIR/$MARAUDER_BOARD/info.txt"
if [[ -f "$INFO_FILE" ]]; then
  echo "📝 Board Info:"
  cat "$INFO_FILE"
  echo
fi

# 📦 Export vars for Docker Compose
export ESP32_VERSION
export ESP32_CHIP
export MARAUDER_BOARD
export FQBN
export CUSTOM_IDF
export CUSTOM_IDF_DIR
export CUSTOM_IDF_BRANCH

echo "🧹 Forcing no cache build..."
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# 🚧 Choose Docker Compose command
DOCKER_COMPOSE_CMD="docker compose"
if ! docker compose version &>/dev/null; then
  if command -v docker-compose &>/dev/null; then
    echo "⚠️ 'docker compose' not found, falling back to 'docker-compose'"
    DOCKER_COMPOSE_CMD="docker-compose"
  else
    echo "❌ Neither 'docker compose' nor 'docker-compose' is available!"
    exit 1
  fi
fi

# 🛠️ Build image
$DOCKER_COMPOSE_CMD build --no-cache \
  --build-arg ESP32_VERSION="$ESP32_VERSION" \
  --build-arg ESP32_CHIP="$ESP32_CHIP" \
  --build-arg MARAUDER_BOARD="$MARAUDER_BOARD" \
  --build-arg CUSTOM_IDF="$CUSTOM_IDF" \
  --build-arg CUSTOM_IDF_DIR="$CUSTOM_IDF_DIR" \
  --build-arg CUSTOM_IDF_BRANCH="$CUSTOM_IDF_BRANCH"


# ▶️ Run container
$DOCKER_COMPOSE_CMD up
