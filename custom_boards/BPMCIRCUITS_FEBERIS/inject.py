#!/usr/bin/env python3
import sys
import argparse

CONFIG_PATH = "/project/ESP32Marauder/esp32_marauder/configs.h"
WIFI_PATH = "/project/ESP32Marauder/esp32_marauder/WiFiScan.cpp"

def log(*args):
    print(" ".join(str(a) for a in args))
    sys.stdout.flush()

def patch_configs_h():
    log("⚙️ Patching configs.h...")
    with open(CONFIG_PATH, "r") as f:
        lines = f.readlines()

    new_lines = []
    in_block = ""
    inserted = {
        "board_targets": False,
        "hardware_name": False,
        "board_features": False,
        "mem_limit": False,
        "html_limit": False,
    }

    for i, line in enumerate(lines):
        stripped = line.strip()

        if "//// BOARD TARGETS" in line:
            in_block = "board_targets"
        elif "//// HARDWARE NAMES" in line:
            in_block = "hardware_name"
        elif "//// BOARD FEATURES" in line:
            in_block = "board_features"
        elif "//// MEMORY LOWER LIMIT STUFF" in line:
            in_block = "mem_limit"
        elif "//// GPS STUFF" in line:
            in_block = "html_limit"  # fallback — upstream przeniósł MAX_HTML_SIZE tuż przed GPS
        elif "//// END" in line:
            if in_block == "board_targets" and not inserted["board_targets"]:
                new_lines.append("  #define BPMCIRCUITS_FEBERIS\n")
                inserted["board_targets"] = True
            elif in_block == "board_features" and not inserted["board_features"]:
                new_lines.append("""\
  #ifdef BPMCIRCUITS_FEBERIS
    //#define FLIPPER_ZERO_HAT
    //#define HAS_BATTERY
    #define HAS_BT
    //#define HAS_BUTTONS
    #define HAS_NEOPIXEL_LED
    //#define HAS_PWR_MGMT
    //#define HAS_SCREEN
    //#define HAS_SD
    //#define HAS_TEMP_SENSOR
    //#define HAS_GPS
  #endif

""")
                inserted["board_features"] = True
            in_block = ""

        # Insert hardware name after last defined() clause
        if in_block == "hardware_name" and "#else" in line and not inserted["hardware_name"]:
            new_lines.append('  #elif defined(BPMCIRCUITS_FEBERIS)\n')
            new_lines.append('    #define HARDWARE_NAME "BPM Circuits FEBERIS"\n')
            inserted["hardware_name"] = True
        # Same for memory limit
        elif in_block == "mem_limit" and "#endif" in line and not inserted["mem_limit"]:
            new_lines.append('  #elif defined(BPMCIRCUITS_FEBERIS)\n')
            new_lines.append('    #define MEM_LOWER_LIM 10000\n')
            inserted["mem_limit"] = True
        # Same for HTML size, added before fallback #else
        elif in_block == "html_limit" and "#else" in line and not inserted["html_limit"]:
            new_lines.append('  #elif defined(BPMCIRCUITS_FEBERIS)\n')
            new_lines.append('    #define MAX_HTML_SIZE 20000\n')
            inserted["html_limit"] = True

        new_lines.append(line)

    with open(CONFIG_PATH, "w") as f:
        f.writelines(new_lines)

    log("✅ configs.h patched successfully.")
    log("✅ configs.h: inserted targets =", inserted['board_targets'],
        ", features =", inserted['board_features'],
        ", mem_limit =", inserted['mem_limit'],
        ", html_limit =", inserted['html_limit'])

def validate_configs_h():
    log("🔍 Validating configs.h...")
    required_lines = [
        "#define BPMCIRCUITS_FEBERIS",
        '#elif defined(BPMCIRCUITS_FEBERIS)',
        '#define HARDWARE_NAME "BPM Circuits FEBERIS"',
        "#define MAX_HTML_SIZE 20000",
        "#define MEM_LOWER_LIM 10000",
    ]

    with open(CONFIG_PATH, "r") as f:
        contents = f.read()

    missing = [line for line in required_lines if line not in contents]

    if missing:
        log("❌ Missing expected injected lines:")
        for line in missing:
            log("   →", line)
        raise SystemExit("⛔ Injection validation failed. Aborting.")
    else:
        log("✅ Injection validation passed.")

def patch_wifi_scan():
    log("⚙️ Patching WiFiScan.cpp...")
    replacements = {
        'sd_obj.removeFile("/Airtags_0.log");': '''#if defined(HAS_SD)
    sd_obj.removeFile("/Airtags_0.log");
  #endif''',
        'sd_obj.removeFile("/APs_0.log");': '''#if defined(HAS_SD)
    sd_obj.removeFile("/APs_0.log");
  #endif''',
        'sd_obj.removeFile("/SSIDs_0.log");': '''#if defined(HAS_SD)
    sd_obj.removeFile("/SSIDs_0.log");
  #endif'''
    }

    with open(WIFI_PATH, "r") as f:
        content = f.read()

    for old, new in replacements.items():
        if old in content:
            content = content.replace(old, new)
            log(f"✅ Patched: {old.strip()}")
        else:
            log(f"⚠️  Not found: {old.strip()}")

    with open(WIFI_PATH, "w") as f:
        f.write(content)

    log("✅ WiFiScan.cpp patched successfully.")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--patch", action="store_true", help="Patch configs.h and WiFiScan.cpp")
    parser.add_argument("--validate", action="store_true", help="Validate configs.h injection")
    parser.add_argument("--all", action="store_true", help="Patch and validate")
    args = parser.parse_args()

    if args.patch:
        patch_configs_h()
        patch_wifi_scan()
    elif args.validate:
        validate_configs_h()
    elif args.all:
        patch_configs_h()
        patch_wifi_scan()
        validate_configs_h()
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
