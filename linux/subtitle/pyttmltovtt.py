#!/usr/bin/env python3

import argparse
import re
import sys
import xml.etree.ElementTree as ET
from decimal import Decimal, ROUND_HALF_UP
from html import unescape

CLOCK_PATTERN = re.compile(
    r"(\d+):([0-5]\d):([0-5]\d)(?:[.,](\d+))?"
)
OFFSET_PATTERN = re.compile(
    r"(\d+(?:[.,]\d+)?)(ms|h|m|s)"
)

TIME_UNITS = {
    "h": Decimal("3600"),
    "m": Decimal("60"),
    "s": Decimal("1"),
    "ms": Decimal("0.001"),
}


def parse_timestamp(value):
    value = value.strip()

    if match := CLOCK_PATTERN.fullmatch(value):
        hours, minutes, seconds, fraction = match.groups()

        total_seconds = (
            Decimal(hours) * 3600
            + Decimal(minutes) * 60
            + Decimal(seconds)
            + Decimal(f"0.{fraction or '0'}")
        )

    elif match := OFFSET_PATTERN.fullmatch(value):
        amount, unit = match.groups()
        total_seconds = Decimal(amount.replace(",", ".")) * TIME_UNITS[unit]

    else:
        raise ValueError(f"Unsupported timestamp: {value}")

    return int(
        (total_seconds * 1000).to_integral_value(
            rounding=ROUND_HALF_UP
        )
    )


def format_timestamp(milliseconds):
    hours, remainder = divmod(milliseconds, 3600000)
    minutes, remainder = divmod(remainder, 60000)
    seconds, milliseconds = divmod(remainder, 1000)

    return f"{hours:02d}:{minutes:02d}:{seconds:02d}.{milliseconds:03d}"


def extract_text(element):
    parts = []

    def collect(node):
        if node.text:
            parts.append(node.text)

        for child in node:
            if child.tag.rsplit("}", 1)[-1] == "br":
                parts.append("\n")
            else:
                collect(child)

            if child.tail:
                parts.append(child.tail)

    collect(element)

    text = unescape("".join(parts))

    return "\n".join(
        " ".join(line.split())
        for line in text.splitlines()
        if line.strip()
    )


def convert_ttml(input_file):
    root = ET.parse(input_file).getroot()
    cues = []

    for element in root.iter():
        if element.tag.rsplit("}", 1)[-1] != "p":
            continue

        begin = element.get("begin")
        end = element.get("end")

        if not begin or not end:
            continue

        text = extract_text(element)

        if not text:
            continue

        start_ms = parse_timestamp(begin)
        end_ms = parse_timestamp(end)

        if end_ms <= start_ms:
            raise ValueError(
                f"Invalid cue timing: {begin} --> {end}"
            )

        cues.append(
            f"{format_timestamp(start_ms)} --> {format_timestamp(end_ms)}\n{text}"
        )

    return "WEBVTT\n\n" + "\n\n".join(cues) + ("\n" if cues else "")


def main():
    parser = argparse.ArgumentParser(
        description="Convert TTML subtitles to WebVTT."
    )
    parser.add_argument(
        "input",
        help="Path to the TTML subtitle file"
    )

    args = parser.parse_args()

    try:
        output = convert_ttml(args.input)
        sys.stdout.write(output)

    except (OSError, ET.ParseError, ValueError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
