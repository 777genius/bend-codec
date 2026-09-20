# Hex / Base64 proof status

Domain: RFC 4648 hex and Base64 over checked `U32` bytes `0..255`. Decode
alphabet `0-9A-Fa-f` for hex; standard / URL alphabets for Base64.

| Claim | Status | Domain |
|---|---|---|
| `encode([], lower) = ""` | proved | empty |
| `decode("") = []` | proved | empty |
| `encode([0,1,254,255], lower) = "0001feff"` | proved | closed |
| `decode("0001feff") = [0,1,254,255]` | proved | closed |
| `encode([170], lower) = "aa"` | proved | one byte |
| `decode("aa") = [170]` | proved | one byte |
| `decode("FF") = [255]` | proved | uppercase |
| nibble `'0'`/`'f'`/`'F'`/`'g'` | proved | closed chars |
| `Base64.encode([]) = ""` | proved | empty |
| `Base64.decode("") = []` | proved | empty |
| `encode([0,1,254,255]) = "AAH+/w=="` | proved | closed |
| `decode("AAH+/w==") = [0,1,254,255]` | proved | closed |
| URL unpadded `AAH-_w` | proved | closed |
| `Utf8.encode("")` empty | proved | empty |
| `Utf8.encode("A") = [65]` | proved | closed |
| UTF-8 `é` / `€` / U+10348 roundtrip | tested | |
| overlong `C0 80` / truncated / `FF` / surrogate | tested | |
| `decode(encode(b))` canonical lowercase hex | tested | empty, golden, `aa`, 20k of `0xAB` |
| Base64 roundtrip / `Zg==` / `Zh==` / mix / space / mid `=` | tested | |
| `256` is `InvalidByte{0, 256}` | tested | |
| odd / `0g` / `0x00` / space fail | tested | |
| `encode(decode(text)) == text` mixed case | not a law | decode accepts two spellings |

No `@unsafe`. No `F32`. Payload walks do not call Base `String.length` /
`String.split` / `List.length`. The 20k hex roundtrip does not call Base
`String.eq` (its `String.cmp` is not tail-recursive; the walk uses its own
accumulator compare).
