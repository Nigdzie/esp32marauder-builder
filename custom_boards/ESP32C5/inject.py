#!/usr/bin/env python3
import argparse

CONFIG_PATH = "/project/ESP32Marauder/esp32_marauder/configs.h"


def patch_configs_h():
    lines = []
    with open(CONFIG_PATH, "r") as f:
        for line in f:
            if line.strip() == "//#define GENERIC_ESP32":
                lines.append("#define GENERIC_ESP32\n")
            else:
                lines.append(line)
    with open(CONFIG_PATH, "w") as f:
        f.writelines(lines)


def validate_configs_h():
    with open(CONFIG_PATH, "r") as f:
        contents = f.read()
    if "#define GENERIC_ESP32" not in contents:
        raise SystemExit("GENERIC_ESP32 not enabled")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--patch", action="store_true")
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--all", action="store_true")
    args = parser.parse_args()

    if args.patch:
        patch_configs_h()
    elif args.validate:
        validate_configs_h()
    elif args.all:
        patch_configs_h()
        validate_configs_h()
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
