#!/usr/bin/env python3
"""
generate_aes_key.py — SmartIoT AES-256 Key Generator
=====================================================
প্রতিটি ESP32 device-এর জন্য আলাদা unique AES-256 key generate করে।

ব্যবহার:
  python3 generate_aes_key.py
  python3 generate_aes_key.py --count 5   # একসাথে ৫টি key

Output: 64 hex character string (32 bytes = AES-256)

secrets.h-এ paste করুন:
  #define AES_BACKUP_KEY_HEX "xxxxxxx...xxx"
"""

import secrets
import argparse
import datetime

def generate_key():
    return secrets.token_hex(32)

def main():
    parser = argparse.ArgumentParser(description="Generate AES-256 keys for SmartIoT ESP32 devices")
    parser.add_argument("--count", type=int, default=1, help="Number of keys to generate")
    args = parser.parse_args()

    print("=" * 70)
    print("SmartIoT AES-256-CBC Key Generator")
    print(f"Generated: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 70)
    print()

    for i in range(args.count):
        key = generate_key()
        device_label = f"Device {i+1}" if args.count > 1 else "Your Device"
        print(f"[{device_label}]")
        print(f'#define AES_BACKUP_KEY_HEX "{key}"')
        print()

    print("⚠️  IMPORTANT:")
    print("  1. প্রতিটি ESP32 device-এ আলাদা key ব্যবহার করুন")
    print("  2. এই key কোথাও সেভ করুন (হারিয়ে গেলে NVS data পড়া যাবে না)")
    print("  3. কখনো git-এ commit করবেন না (secrets.h .gitignore-এ আছে)")
    print()

if __name__ == "__main__":
    main()
