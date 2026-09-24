# bend-codec

RFC 4648 hex, Base64, and UTF-8 for [Bend 2](https://github.com/bendlang/bend). One package hash. Shared `Bytes`: checked `U32` values `0..255`.

## Install

Hub name `bend-codec-lib@0.2.0.0` (the name must be ≥12 characters). Same tree as hash `0x888714bde93f46c139372bb9fdc57a19`.

```python
import bend-codec-lib@0.2.0.0/hex.bend as H
import bend-codec-lib@0.2.0.0/base64.bend as B64
import bend-codec-lib@0.2.0.0/utf8.bend as U
```

[name](https://hub.bend-lang.com/n/bend-codec-lib) · [hex](https://hub.bend-lang.com/0x888714bde93f46c139372bb9fdc57a19/hex.bend) · [base64](https://hub.bend-lang.com/0x888714bde93f46c139372bb9fdc57a19/base64.bend) · [utf8](https://hub.bend-lang.com/0x888714bde93f46c139372bb9fdc57a19/utf8.bend) · [manifest](https://hub.bend-lang.com/0x888714bde93f46c139372bb9fdc57a19/manifest)

This is v0.2.0. From this repo: `import ./hex.bend as H`. The hash still works: `import 0x888714bde93f46c139372bb9fdc57a19/hex.bend as H`.

## Example

```python
import Base
import ./hex.bend as H

def Readme.from_result(
  r: Result<&2, &2, H.Hex.Error, String>
) -> String:
  match r:
    case Done{s}:
      s
    case Fail{_}:
      "fail"

def main() -> IO(Unit):
  IO.print(
    Readme.from_result(
      H.Hex.encode_u32_list([0, 1, 254, 255], H.HexLower{})
    )
  )
```

Prints `0001feff`. Copy: [`examples/readme.bend`](examples/readme.bend). Base64: [`examples/base64.bend`](examples/base64.bend) prints `AAH+/w==`. UTF-8 then hex: [`examples/utf8.bend`](examples/utf8.bend) prints `6869` for `"hi"`.

The helper is required: Bend cannot `match` a computed `Result`.

## API

```text
Hex.encode(bytes, casing) -> String
Hex.decode(text) -> Result<Bytes, Hex.Error>
Hex.encode_u32_list(values, casing) -> Result<String, Hex.Error>
Hex.decode_u32_list(text) -> Result<List<U32>, Hex.Error>

Base64.encode(bytes) -> String
Base64.decode(text) -> Result<Bytes, Base64.Error>
Base64Url.encode(bytes, padded) -> String
Base64Url.decode(text, padded) -> Result<Bytes, Base64.Error>

Utf8.encode(text) -> Result<Bytes, Utf8.Error>
Utf8.decode(bytes) -> Result<String, Utf8.Error>
```

- Encode default in docs is lowercase (`HexLower{}`).
- Hex decode: `0-9A-Fa-f` only. Odd length, `0x`, spaces, and any other character are `Fail`. Empty ↔ empty.
- `256` is `InvalidByte` at that index, not wrap.
- `Hex.Error` is `InvalidChar{offset, char}`, `OddLength{offset}`, or `InvalidByte{index, value}`. Offsets are 0-based characters. Errors do not echo the payload.
- Standard Base64 is padded. URL alphabet takes a `padded` flag. Spaces, mixed alphabets, mid `=`, and non-canonical leftover bits (`Zh==`) are `Fail`. `Zg==` is ok.
- UTF-8 encode/decode over Unicode scalar values. Overlong forms, surrogates, truncated sequences, and `> U+10FFFF` are `Fail`.

From JS, `List` is `{ $: "Con", head, tail }` / `{ $: "Nil" }`, `HexLower` is `{ $: "HexLower" }`, `Nat` is `BigInt`, `U32` is a number. See `js_smoke.mjs`.

v0.2 is not Base32, not a streaming encoder, and does not accept hex with spaces or a `0x` prefix.

## Proofs

Closed roundtrips are **proved**. Mixed-case `encode(decode(text)) == text` is false; it is not a law. README fixtures are **tested** on JS and native. Table: [docs/proof-status.md](docs/proof-status.md).

## Check

Bend **2.0.5** (`0b7e2b11`), bun 1.3.11, clang 14+. Pin: [docs/compatibility.md](docs/compatibility.md).

```sh
./tools/e2e
```

## License

Apache-2.0. Copyright 2026 Илия.
