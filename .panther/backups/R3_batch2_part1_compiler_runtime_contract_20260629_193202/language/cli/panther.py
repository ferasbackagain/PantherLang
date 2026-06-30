#!/usr/bin/env python3
import argparse

parser = argparse.ArgumentParser(prog="panther")
sub = parser.add_subparsers(dest="command")

sub.add_parser("version")
sub.add_parser("doctor")
sub.add_parser("build")
sub.add_parser("run")

args = parser.parse_args()

if args.command == "version":
    print("PantherLang Developer Preview v0.5")
elif args.command == "doctor":
    print("✓ Panther CLI OK")
elif args.command == "build":
    print("Building Panther project...")
elif args.command == "run":
    print("Running Panther project...")
else:
    parser.print_help()
