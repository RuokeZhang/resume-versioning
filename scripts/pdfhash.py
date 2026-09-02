#!/usr/bin/env python3
"""Fingerprint a PDF's rendered content, ignoring metadata.

Hashes the decompressed content streams so the result is stable across runs of
the same source but moves on any layout or text change.

/CreationDate is redacted: tectonic stamps the wall clock into the document
info dictionary, so without this two compiles of identical source produce
different hashes and the comparison is useless.

    python3 pdfhash.py a.pdf            -> 97080675e88112c4 streams=10
    python3 pdfhash.py a.pdf b.pdf ...  -> one line per file
"""
import sys
import re
import zlib
import hashlib


def fingerprint(path):
    data = open(path, 'rb').read()
    h = hashlib.sha256()
    n = 0
    for m in re.finditer(rb'stream\r?\n', data):
        start = m.end()
        end = data.find(b'endstream', start)
        if end < 0:
            continue
        try:
            chunk = zlib.decompress(data[start:end])
        except Exception:
            continue  # font blob or already-raw stream
        if b'Tj' in chunk or b'TJ' in chunk or b're' in chunk:
            h.update(re.sub(rb"/CreationDate\([^)]*\)", b"", chunk))
            n += 1
    return h.hexdigest()[:16], n


if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    for path in sys.argv[1:]:
        digest, n = fingerprint(path)
        if len(sys.argv) > 2:
            print(f'{digest} streams={n}  {path}')
        else:
            print(f'{digest} streams={n}')
