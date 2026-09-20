import Base
import ./bytes.bend as B

type HexCase is Data:
  HexLower{}
  HexUpper{}

type Hex.Error is Data:
  InvalidChar{offset: Nat, char: Char}
  OddLength{offset: Nat}
  InvalidByte{index: Nat, value: U32}

type Hex.Pend is Data:
  PendNone{}
  PendHi{hi: U32}

def Hex.from_bytes_err(e: B.Bytes.Error) -> Hex.Error:
  match e:
    case B.InvalidByte{index, value}:
      InvalidByte{index, value}

def Hex.lo_digit_if(+n: U32, is_num: Bool) -> Char:
  match is_num:
    case True{}:
      Char.from_u32((Char.to_u32('0') + n : U32))
    case False{}:
      Char.from_u32((Char.to_u32('a') + (n - 10 : U32) : U32))

def Hex.lo_digit(+n: U32) -> Char:
  Hex.lo_digit_if(n, U32.is_lt(n, 10))

def Hex.up_digit_if(+n: U32, is_num: Bool) -> Char:
  match is_num:
    case True{}:
      Char.from_u32((Char.to_u32('0') + n : U32))
    case False{}:
      Char.from_u32((Char.to_u32('A') + (n - 10 : U32) : U32))

def Hex.up_digit(+n: U32) -> Char:
  Hex.up_digit_if(n, U32.is_lt(n, 10))

def Hex.digit(+n: U32, c: HexCase) -> Char:
  match c:
    case HexLower{}:
      Hex.lo_digit(n)
    case HexUpper{}:
      Hex.up_digit(n)

def Hex.encode.byte(+b: U32, acc: String, +casing: HexCase) -> String:
  hi = U32.shrn(b, 4n)
  lo = U32.and(b, 15)
  SCon{Hex.digit(lo, casing), SCon{Hex.digit(hi, casing), acc}}

def Hex.encode.go(xs: List<&2, U32>, acc: String, +casing: HexCase) -> String:
  match xs:
    case Nil{}:
      String.reverse(acc)
    case Con{+h, t}:
      Hex.encode.go(t, Hex.encode.byte(h, acc, casing), casing)

def Hex.encode(bytes: B.Bytes, casing: HexCase) -> String:
  match bytes:
    case B.Bytes{data}:
      Hex.encode.go(data, SNil{}, casing)

def Hex.nibble.af2(+x: U32, le: Bool) -> Maybe<&2, U32>:
  match le:
    case True{}:
      Some{(x - Char.to_u32('7') : U32)}
    case False{}:
      None{}

def Hex.nibble.af(+x: U32, ge: Bool) -> Maybe<&2, U32>:
  match ge:
    case False{}:
      None{}
    case True{}:
      Hex.nibble.af2(x, U32.is_le(x, Char.to_u32('F')))

def Hex.nibble.az2(+x: U32, le: Bool) -> Maybe<&2, U32>:
  match le:
    case True{}:
      Some{(x - Char.to_u32('W') : U32)}
    case False{}:
      Hex.nibble.af(x, U32.is_ge(x, Char.to_u32('A')))

def Hex.nibble.az(+x: U32, ge: Bool) -> Maybe<&2, U32>:
  match ge:
    case False{}:
      Hex.nibble.af(x, U32.is_ge(x, Char.to_u32('A')))
    case True{}:
      Hex.nibble.az2(x, U32.is_le(x, Char.to_u32('f')))

def Hex.nibble.d092(+x: U32, le: Bool) -> Maybe<&2, U32>:
  match le:
    case True{}:
      Some{(x - Char.to_u32('0') : U32)}
    case False{}:
      Hex.nibble.az(x, U32.is_ge(x, Char.to_u32('a')))

def Hex.nibble.d09(+x: U32, ge: Bool) -> Maybe<&2, U32>:
  match ge:
    case False{}:
      Hex.nibble.az(x, U32.is_ge(x, Char.to_u32('a')))
    case True{}:
      Hex.nibble.d092(x, U32.is_le(x, Char.to_u32('9')))

def Hex.nibble.u(+x: U32) -> Maybe<&2, U32>:
  Hex.nibble.d09(x, U32.is_ge(x, Char.to_u32('0')))

def Hex.nibble(c: Char) -> Maybe<&2, U32>:
  Hex.nibble.u(Char.to_u32(c))

def Hex.decode.go(
  s: String, n: Maybe<&2, U32>, +h: Char, pend: Hex.Pend, acc: List<&2, U32>,
  off: Nat
) -> Result<&2, &2, Hex.Error, B.Bytes>:
  match s n pend:
    case _ None{} _:
      Fail{InvalidChar{off, h}}
    case SNil{} Some{_} PendNone{}:
      Fail{OddLength{1n+off}}
    case SNil{} Some{v} PendHi{hi}:
      Done{
        B.Bytes{
          List.reverse(&2, U32, Con{U32.or(U32.shln(hi, 4n), v), acc})
        }
      }
    case SCon{+h2, t} Some{v} PendNone{}:
      Hex.decode.go(t, Hex.nibble(h2), h2, PendHi{v}, acc, 1n+off)
    case SCon{+h2, t} Some{v} PendHi{hi}:
      Hex.decode.go(
        t, Hex.nibble(h2), h2, PendNone{},
        Con{U32.or(U32.shln(hi, 4n), v), acc}, 1n+off
      )

def Hex.decode.start(
  s: String
) -> Result<&2, &2, Hex.Error, B.Bytes>:
  match s:
    case SNil{}:
      Done{B.Bytes{Nil{}}}
    case SCon{+h, t}:
      Hex.decode.go(t, Hex.nibble(h), h, PendNone{}, Nil{}, 0n)

def Hex.decode(text: String) -> Result<&2, &2, Hex.Error, B.Bytes>:
  Hex.decode.start(text)

def Hex.encode_u32_list.from(
  r: Result<&2, &2, B.Bytes.Error, B.Bytes>, +casing: HexCase
) -> Result<&2, &2, Hex.Error, String>:
  match r:
    case Fail{e}:
      Fail{Hex.from_bytes_err(e)}
    case Done{b}:
      Done{Hex.encode(b, casing)}

def Hex.encode_u32_list(
  values: List<&2, U32>, casing: HexCase
) -> Result<&2, &2, Hex.Error, String>:
  Hex.encode_u32_list.from(B.Bytes.from_u32_list(values), casing)

def Hex.decode_u32_list.from(
  r: Result<&2, &2, Hex.Error, B.Bytes>
) -> Result<&2, &2, Hex.Error, List<&2, U32>>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{b}:
      Done{B.Bytes.to_u32_list(b)}

def Hex.decode_u32_list(
  text: String
) -> Result<&2, &2, Hex.Error, List<&2, U32>>:
  Hex.decode_u32_list.from(Hex.decode(text))
