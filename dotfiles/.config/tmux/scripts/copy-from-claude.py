#!/usr/bin/env python3
"""Turn a tmux copy-mode selection of Claude Code output back into the exact
text Claude wrote.

Claude Code wraps long lines itself and indents every row, so the screen grid
has line breaks that are not in the original. Whitespace is the only thing
that wrapping changes, so this strips all whitespace from the selection, finds
that string in recent Claude Code transcripts with whitespace stripped the same
way, and emits the original span: real line breaks kept, wrap breaks gone.

No match: emits the selection unchanged minus one trailing newline, like `y`.
Reads stdin, writes stdout; pipe to pbcopy.
"""
import glob
import json
import os
import re
import sys
import time

MAX_AGE_SECONDS = 2 * 24 * 3600
MAX_FILES = 20
WS = re.compile(r"\s")


def transcripts():
    root = os.environ.get("CLAUDE_PROJECTS", os.path.expanduser("~/.claude/projects"))
    now = time.time()
    files = []
    for path in glob.glob(os.path.join(root, "*", "*.jsonl")):
        try:
            mtime = os.path.getmtime(path)
        except OSError:
            continue
        if now - mtime <= MAX_AGE_SECONDS:
            files.append((mtime, path))
    return [p for _, p in sorted(files, reverse=True)[:MAX_FILES]]


def assistant_texts(path):
    """Assistant text blocks in a transcript, newest first."""
    texts = []
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            if '"assistant"' not in line:
                continue
            try:
                entry = json.loads(line)
            except ValueError:
                continue
            if entry.get("type") != "assistant":
                continue
            content = entry.get("message", {}).get("content")
            if not isinstance(content, list):
                continue
            for block in content:
                if isinstance(block, dict) and block.get("type") == "text":
                    texts.append(block.get("text", ""))
    return reversed(texts)


def find_original(key, text):
    """Span of text whose non-whitespace characters equal key, or None."""
    positions = [i for i, ch in enumerate(text) if not WS.match(ch)]
    stripped = "".join(text[i] for i in positions)
    at = stripped.rfind(key)
    if at < 0:
        return None
    return text[positions[at] : positions[at + len(key) - 1] + 1]


def main():
    selection = sys.stdin.read()
    key = WS.sub("", selection)
    if key:
        for path in transcripts():
            for text in assistant_texts(path):
                if key in WS.sub("", text):
                    found = find_original(key, text)
                    if found is not None:
                        sys.stdout.write(found)
                        return 0
    sys.stdout.write(selection[:-1] if selection.endswith("\n") else selection)
    return 1


if __name__ == "__main__":
    sys.exit(main())
