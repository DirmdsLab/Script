#!/usr/bin/env python3

import sys
import xml.etree.ElementTree as ET
from html import unescape

ns = {"tt": "http://www.w3.org/ns/ttml"}

tree = ET.parse(sys.argv[1])
root = tree.getroot()

print("WEBVTT\n")

for p in root.findall(".//tt:p", ns):
    begin = p.attrib["begin"]
    end = p.attrib["end"]

    begin = begin.replace(",", ".")
    end = end.replace(",", ".")

    text = "".join(p.itertext()).strip()
    text = unescape(text)

    print(f"{begin} --> {end}")
    print(text)
    print()
