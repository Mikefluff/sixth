#!/usr/bin/env python3
"""
extract.py — extract attention patterns from Pythia.

SCAFFOLD STUB.  Not executable in current state.  See README.md
for the full design and DESIGN.md for the encoding scheme.

When executed (TODO: implement):
  - Load Pythia model from Hugging Face Hub
  - Run inference on a standardized prompt set
  - Extract per-(layer, head, prompt) attention matrices
  - Save to disk as numpy arrays for encode.py to consume

Usage (when implemented):
  python extract.py --model EleutherAI/pythia-1.4b \
                    --prompts prompts/lambada-1k.jsonl \
                    --output attn-cache/
"""

import sys


def main():
    print("SCAFFOLD ONLY — not yet implemented.", file=sys.stderr)
    print("See README.md and DESIGN.md for the planned implementation.",
          file=sys.stderr)
    print("This stub exists to mark the file's role in the pipeline.",
          file=sys.stderr)
    sys.exit(1)


if __name__ == "__main__":
    main()
