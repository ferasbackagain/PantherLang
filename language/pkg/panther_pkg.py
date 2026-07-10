#!/usr/bin/env python3
import argparse
parser=argparse.ArgumentParser(prog="panther-pkg")
sub=parser.add_subparsers(dest="cmd")
for c in ["init","install","list","publish"]:
    sub.add_parser(c)
a=parser.parse_args()
if a.cmd=="init":
    print("Initialized panther.pkg")
elif a.cmd=="install":
    print("Package installation placeholder")
elif a.cmd=="list":
    print("Core packages:\npanther.core\npanther.math\npanther.ai")
elif a.cmd=="publish":
    print("Publish placeholder")
else:
    parser.print_help()
