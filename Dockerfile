FROM ubuntu:22.04

ARG ESP32_VERSION
ARG ESP32_CHIP
ARG MARAUDER_BOARD

ENV PATH="/root/bin:$PATH"

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y \
    curl unzip git xz-utils python3 python3-pip nano \
    gcc make jq sed && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh

RUN arduino-cli config init && \
    arduino-cli core update-index && \
    arduino-cli core install esp32:esp32@${ESP32_VERSION}

COPY custom_boards/$MARAUDER_BOARD/ /tmp/

RUN if [[ -f /tmp/libs.txt ]]; then \
      grep -v '^#' /tmp/libs.txt | grep -v '^\s*$' | while read lib; do \
        echo "📦 Installing $lib..."; \
        until arduino-cli lib install "$lib"; do \
          echo "🔁 Retrying $lib in 5s..."; sleep 5; \
        done; \
      done; \
    else \
      echo "⚠️ No libs.txt found – skipping Arduino library install."; \
    fi

RUN if [[ -f /tmp/libs_git.txt ]]; then \
      mkdir -p /root/Arduino/libraries && cd /root/Arduino/libraries && \
      while IFS=@ read -r REPO VERSION; do \
        DIR=$(basename "$REPO" .git); \
        echo "⬇️ Cloning $DIR@$VERSION..."; \
        git clone "$REPO" "$DIR" || exit 1 && \
        cd "$DIR" && git checkout "$VERSION" || exit 1 && cd ..; \
      done < /tmp/libs_git.txt; \
    else \
      echo "⚠️ No libs_git.txt found – skipping external Git libraries."; \
    fi

RUN pip3 install pyserial

RUN rm -rf /project/ESP32Marauder && \
    git clone --depth=1 https://github.com/justcallmekoko/ESP32Marauder.git /project/ESP32Marauder

RUN if [[ -f /tmp/inject.py ]]; then \
      echo "🚀 Running inject.py for $MARAUDER_BOARD"; \
      mkdir -p /project/output && \
      python3 /tmp/inject.py --all > /tmp/inject.log 2>&1 && \
      cat /tmp/inject.log; \
    else \
      echo "🧘 Skipping inject.py – not found at /tmp/inject.py"; \
    fi

RUN echo "📂 Copying Files to esp32_marauder"; \
    if [[ -d /tmp/Files ]]; then \
      echo "📂 Copying Files to esp32_marauder"; \
      cp -rv /tmp/Files/* /project/ESP32Marauder/esp32_marauder/; \
    fi

RUN if [[ -d /tmp/Libs ]]; then \
      mkdir -p /root/Arduino/libraries/ && \
      echo "📂 Copying Libs to /root/Arduino/libraries/"; \
      cp -rv /tmp/Libs/* /root/Arduino/libraries/; \
    else \
      echo "📭 No Libs directory found – skipping."; \
    fi

RUN mkdir -p /root/.arduino15/packages/esp32/hardware/esp32/${ESP32_VERSION}
COPY platform.txt /root/.arduino15/packages/esp32/hardware/esp32/${ESP32_VERSION}/platform.txt

WORKDIR /project

RUN if [[ -f /project/ESP32Marauder/esp32_marauder/esp32_marauder.ino ]]; then \
      chmod +r /project/ESP32Marauder/esp32_marauder/esp32_marauder.ino; \
    fi
