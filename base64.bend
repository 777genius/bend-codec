import Base
import ./bytes.bend as B

type B64.Alpha is Data:
  B64Std{}
  B64Url{}

type B64.Pad is Data:
  B64Pad{}
  B64Raw{}

type B64.G is Data:
  G0{}
  G1{}
  G2{}

type B64.D is Data:
  D0{}
  D1{a: U32}
  D2{a: U32, b: U32}
  D3{a: U32, b: U32, c: U32}
  Eq1{a: U32, b: U32}
  PadEnd{}

type B64.Tok is Data:
  TokVal{n: U32}
  TokPad{}
  TokBad{c: Char}

type Base64.Error is Data:
  InvalidChar{offset: Nat, char: Char}
  InvalidLength{offset: Nat}
  NonCanonical{offset: Nat}
  InvalidByte{index: Nat, value: U32}

def Base64.from_bytes_err(e: B.Bytes.Error) -> Base64.Error:
  match e:
    case B.InvalidByte{index, value}:
      InvalidByte{index, value}

def B64.ch.62(alpha: B64.Alpha) -> Char:
  match alpha:
    case B64Std{}:
      '+'
    case B64Url{}:
      '-'

def B64.ch.63(alpha: B64.Alpha) -> Char:
  match alpha:
    case B64Std{}:
      '/'
    case B64Url{}:
      '_'

def B64.ch.pm(+alpha: B64.Alpha, is62: Bool) -> Char:
  match is62:
    case True{}:
      B64.ch.62(alpha)
    case False{}:
      B64.ch.63(alpha)

def B64.ch.lt62(+n: U32, lt: Bool, +alpha: B64.Alpha) -> Char:
  match lt:
    case True{}:
      Char.from_u32((Char.to_u32('0') + (n - 52 : U32) : U32))
    case False{}:
      B64.ch.pm(alpha, U32.is_eq(n, 62))

def B64.ch.lt52(+n: U32, lt: Bool, +alpha: B64.Alpha) -> Char:
  match lt:
    case True{}:
      Char.from_u32((Char.to_u32('a') + (n - 26 : U32) : U32))
    case False{}:
      B64.ch.lt62(n, U32.is_lt(n, 62), alpha)

def B64.ch.lt26(+n: U32, lt: Bool, +alpha: B64.Alpha) -> Char:
  match lt:
    case True{}:
      Char.from_u32((Char.to_u32('A') + n : U32))
    case False{}:
      B64.ch.lt52(n, U32.is_lt(n, 52), alpha)

def B64.ch(+n: U32, +alpha: B64.Alpha) -> Char:
  B64.ch.lt26(n, U32.is_lt(n, 26), alpha)

def B64.push4(
  s0: U32, s1: U32, s2: U32, s3: U32, acc: String, +alpha: B64.Alpha
) -> String:
  SCon{
    B64.ch(s3, alpha),
    SCon{
      B64.ch(s2, alpha),
      SCon{B64.ch(s1, alpha), SCon{B64.ch(s0, alpha), acc}}
    }
  }

def B64.emit3(+a: U32, +b: U32, +c: U32, acc: String, +alpha: B64.Alpha) -> String:
  B64.push4(
    U32.shrn(a, 2n),
    U32.or(U32.shln(U32.and(a, 3), 4n), U32.shrn(b, 4n)),
    U32.or(U32.shln(U32.and(b, 15), 2n), U32.shrn(c, 6n)),
    U32.and(c, 63),
    acc,
    alpha
  )

def B64.pad1.fin(
  s0: U32, s1: U32, acc: String, +alpha: B64.Alpha, pad: B64.Pad
) -> String:
  match pad:
    case B64Pad{}:
      SCon{
        '=', SCon{'=', SCon{B64.ch(s1, alpha), SCon{B64.ch(s0, alpha), acc}}}
      }
    case B64Raw{}:
      SCon{B64.ch(s1, alpha), SCon{B64.ch(s0, alpha), acc}}

def B64.pad1(+a: U32, acc: String, +alpha: B64.Alpha, pad: B64.Pad) -> String:
  B64.pad1.fin(U32.shrn(a, 2n), U32.shln(U32.and(a, 3), 4n), acc, alpha, pad)

def B64.pad2.fin(
  s0: U32, s1: U32, s2: U32, acc: String, +alpha: B64.Alpha, pad: B64.Pad
) -> String:
  match pad:
    case B64Pad{}:
      SCon{
        '=',
        SCon{
          B64.ch(s2, alpha),
          SCon{B64.ch(s1, alpha), SCon{B64.ch(s0, alpha), acc}}
        }
      }
    case B64Raw{}:
      SCon{
        B64.ch(s2, alpha), SCon{B64.ch(s1, alpha), SCon{B64.ch(s0, alpha), acc}}
      }

def B64.pad2(+a: U32, +b: U32, acc: String, +alpha: B64.Alpha, pad: B64.Pad) -> String:
  B64.pad2.fin(
    U32.shrn(a, 2n),
    U32.or(U32.shln(U32.and(a, 3), 4n), U32.shrn(b, 4n)),
    U32.shln(U32.and(b, 15), 2n),
    acc,
    alpha,
    pad
  )

def Base64.encode.go(
  xs: List<&2, U32>, phase: B64.G, a: U32, b: U32, acc: String,
  +alpha: B64.Alpha, +pad: B64.Pad
) -> String:
  match xs phase:
    case Nil{} G0{}:
      String.reverse(acc)
    case Nil{} G1{}:
      String.reverse(B64.pad1(a, acc, alpha, pad))
    case Nil{} G2{}:
      String.reverse(B64.pad2(a, b, acc, alpha, pad))
    case Con{+h, t} G0{}:
      Base64.encode.go(t, G1{}, h, 0, acc, alpha, pad)
    case Con{+h, t} G1{}:
      Base64.encode.go(t, G2{}, a, h, acc, alpha, pad)
    case Con{+h, t} G2{}:
      Base64.encode.go(t, G0{}, 0, 0, B64.emit3(a, b, h, acc, alpha), alpha, pad)

def Base64.encode.with(bytes: B.Bytes, +alpha: B64.Alpha, +pad: B64.Pad) -> String:
  match bytes:
    case B.Bytes{data}:
      Base64.encode.go(data, G0{}, 0, 0, SNil{}, alpha, pad)

def Base64.encode(bytes: B.Bytes) -> String:
  Base64.encode.with(bytes, B64Std{}, B64Pad{})

def Base64Url.encode.p(bytes: B.Bytes, padded: Bool) -> String:
  match padded:
    case True{}:
      Base64.encode.with(bytes, B64Url{}, B64Pad{})
    case False{}:
      Base64.encode.with(bytes, B64Url{}, B64Raw{})

def Base64Url.encode(bytes: B.Bytes, padded: Bool) -> String:
  Base64Url.encode.p(bytes, padded)

def B64.tok.under.yes(alpha: B64.Alpha, +c: Char) -> B64.Tok:
  match alpha:
    case B64Url{}:
      TokVal{63}
    case B64Std{}:
      TokBad{c}

def B64.tok.under(under: Bool, alpha: B64.Alpha, +c: Char) -> B64.Tok:
  match under:
    case False{}:
      TokBad{c}
    case True{}:
      B64.tok.under.yes(alpha, c)

def B64.tok.minus.yes(alpha: B64.Alpha, +c: Char) -> B64.Tok:
  match alpha:
    case B64Url{}:
      TokVal{62}
    case B64Std{}:
      TokBad{c}

def B64.tok.minus(minus: Bool, +alpha: B64.Alpha, +c: Char) -> B64.Tok:
  match minus:
    case True{}:
      B64.tok.minus.yes(alpha, c)
    case False{}:
      B64.tok.under(Char.is_eq(c, '_'), alpha, c)

def B64.tok.slash.yes(alpha: B64.Alpha, +c: Char) -> B64.Tok:
  match alpha:
    case B64Std{}:
      TokVal{63}
    case B64Url{}:
      TokBad{c}

def B64.tok.slash(slash: Bool, +alpha: B64.Alpha, +c: Char) -> B64.Tok:
  match slash:
    case True{}:
      B64.tok.slash.yes(alpha, c)
    case False{}:
      B64.tok.minus(Char.is_eq(c, '-'), alpha, c)

def B64.tok.plus.yes(alpha: B64.Alpha, +c: Char) -> B64.Tok:
  match alpha:
    case B64Std{}:
      TokVal{62}
    case B64Url{}:
      TokBad{c}

def B64.tok.plus(plus: Bool, +alpha: B64.Alpha, +c: Char) -> B64.Tok:
  match plus:
    case True{}:
      B64.tok.plus.yes(alpha, c)
    case False{}:
      B64.tok.slash(Char.is_eq(c, '/'), alpha, c)

def B64.tok.sym(+c: Char, +alpha: B64.Alpha) -> B64.Tok:
  B64.tok.plus(Char.is_eq(c, '+'), alpha, c)

def B64.tok.az2(+x: U32, +c: Char, +alpha: B64.Alpha, le: Bool) -> B64.Tok:
  match le:
    case True{}:
      TokVal{(x - Char.to_u32('G') : U32)}
    case False{}:
      B64.tok.sym(c, alpha)

def B64.tok.az(+x: U32, +c: Char, +alpha: B64.Alpha, ge: Bool) -> B64.Tok:
  match ge:
    case False{}:
      B64.tok.sym(c, alpha)
    case True{}:
      B64.tok.az2(x, c, alpha, U32.is_le(x, Char.to_u32('z')))

def B64.tok.AZ2(+x: U32, +c: Char, +alpha: B64.Alpha, le: Bool) -> B64.Tok:
  match le:
    case True{}:
      TokVal{(x - Char.to_u32('A') : U32)}
    case False{}:
      B64.tok.az(x, c, alpha, U32.is_ge(x, Char.to_u32('a')))

def B64.tok.AZ(+x: U32, +c: Char, +alpha: B64.Alpha, ge: Bool) -> B64.Tok:
  match ge:
    case False{}:
      B64.tok.az(x, c, alpha, U32.is_ge(x, Char.to_u32('a')))
    case True{}:
      B64.tok.AZ2(x, c, alpha, U32.is_le(x, Char.to_u32('Z')))

def B64.tok.d092(+x: U32, +c: Char, +alpha: B64.Alpha, le: Bool) -> B64.Tok:
  match le:
    case True{}:
      TokVal{(x - Char.to_u32('0') + 52 : U32)}
    case False{}:
      B64.tok.AZ(x, c, alpha, U32.is_ge(x, Char.to_u32('A')))

def B64.tok.d09(+x: U32, +c: Char, +alpha: B64.Alpha, ge: Bool) -> B64.Tok:
  match ge:
    case False{}:
      B64.tok.AZ(x, c, alpha, U32.is_ge(x, Char.to_u32('A')))
    case True{}:
      B64.tok.d092(x, c, alpha, U32.is_le(x, Char.to_u32('9')))

def B64.tok.eq(+x: U32, +c: Char, +alpha: B64.Alpha, eq: Bool) -> B64.Tok:
  match eq:
    case True{}:
      TokPad{}
    case False{}:
      B64.tok.d09(x, c, alpha, U32.is_ge(x, Char.to_u32('0')))

def B64.tok.u(+x: U32, +c: Char, +alpha: B64.Alpha) -> B64.Tok:
  B64.tok.eq(x, c, alpha, U32.is_eq(x, Char.to_u32('=')))

def B64.tok(+c: Char, +alpha: B64.Alpha) -> B64.Tok:
  B64.tok.u(Char.to_u32(c), c, alpha)

def B64.zero4(b: U32) -> Bool:
  U32.is_eq(U32.and(b, 15), 0)

def B64.zero2(c: U32) -> Bool:
  U32.is_eq(U32.and(c, 3), 0)

def B64.byte1(+a: U32, +b: U32) -> U32:
  U32.or(U32.shln(a, 2n), U32.shrn(b, 4n))

def B64.byte2(+b: U32, +c: U32) -> U32:
  U32.or(U32.shln(U32.and(b, 15), 4n), U32.shrn(c, 2n))

def B64.byte3(+c: U32, d: U32) -> U32:
  U32.or(U32.shln(U32.and(c, 3), 6n), d)

def B64.fin1(
  ok: Bool, +a: U32, +b: U32, acc: List<&2, U32>, off: Nat
) -> Result<&2, &2, Base64.Error, B.Bytes>:
  match ok:
    case False{}:
      Fail{NonCanonical{off}}
    case True{}:
      Done{B.Bytes{List.reverse(&2, U32, Con{B64.byte1(a, b), acc})}}

def B64.fin1.from(+a: U32, +b: U32, acc: List<&2, U32>, off: Nat) ->
  Result<&2, &2, Base64.Error, B.Bytes>:
  B64.fin1(B64.zero4(b), a, b, acc, off)

def B64.fin2(
  ok: Bool, +a: U32, +b: U32, +c: U32, acc: List<&2, U32>, off: Nat
) -> Result<&2, &2, Base64.Error, B.Bytes>:
  match ok:
    case False{}:
      Fail{NonCanonical{off}}
    case True{}:
      Done{
        B.Bytes{
          List.reverse(
            &2, U32, Con{B64.byte2(b, c), Con{B64.byte1(a, b), acc}}
          )
        }
      }

def B64.fin2.from(+a: U32, +b: U32, +c: U32, acc: List<&2, U32>, off: Nat) ->
  Result<&2, &2, Base64.Error, B.Bytes>:
  B64.fin2(B64.zero2(c), a, b, c, acc, off)

def B64.emit2(+a: U32, +b: U32, +c: U32, acc: List<&2, U32>) -> List<&2, U32>:
  Con{B64.byte2(b, c), Con{B64.byte1(a, b), acc}}

def B64.emit4(
  +a: U32, +b: U32, +c: U32, d: U32, acc: List<&2, U32>
) -> List<&2, U32>:
  Con{B64.byte3(c, d), Con{B64.byte2(b, c), Con{B64.byte1(a, b), acc}}}

def Base64.decode.go(
  s: String, tok: B64.Tok, st: B64.D, pad: B64.Pad, acc: List<&2, U32>,
  off: Nat, +alpha: B64.Alpha
) -> Result<&2, &2, Base64.Error, B.Bytes>:
  match s tok st pad:
    case _ TokBad{c} _ _:
      Fail{InvalidChar{off, c}}
    case SNil{} TokVal{n} D0{} _:
      Fail{InvalidLength{off}}
    case SNil{} TokVal{n} D1{a} B64Raw{}:
      B64.fin1.from(a, n, acc, off)
    case SNil{} TokVal{_} D1{_} B64Pad{}:
      Fail{InvalidLength{off}}
    case SNil{} TokVal{n} D2{a, b} B64Raw{}:
      B64.fin2.from(a, b, n, acc, off)
    case SNil{} TokVal{_} D2{_, _} B64Pad{}:
      Fail{InvalidLength{off}}
    case SNil{} TokVal{n} D3{a, b, c} _:
      Done{B.Bytes{List.reverse(&2, U32, B64.emit4(a, b, c, n, acc))}}
    case SNil{} TokPad{} D2{a, b} B64Pad{}:
      Fail{InvalidLength{off}}
    case SNil{} TokPad{} D3{a, b, c} B64Pad{}:
      B64.fin2.from(a, b, c, acc, off)
    case SNil{} TokPad{} Eq1{a, b} B64Pad{}:
      B64.fin1.from(a, b, acc, off)
    case SNil{} TokPad{} PadEnd{} B64Pad{}:
      Fail{InvalidLength{off}}
    case SNil{} TokPad{} _ _:
      Fail{InvalidLength{off}}
    case SNil{} TokVal{_} Eq1{_, _} _:
      Fail{InvalidLength{off}}
    case SNil{} TokVal{_} PadEnd{} _:
      Fail{InvalidLength{off}}
    case SCon{+h, t} TokVal{n} D0{} p:
      Base64.decode.go(t, B64.tok(h, alpha), D1{n}, p, acc, 1n+off, alpha)
    case SCon{+h, t} TokVal{n} D1{a} p:
      Base64.decode.go(t, B64.tok(h, alpha), D2{a, n}, p, acc, 1n+off, alpha)
    case SCon{+h, t} TokVal{n} D2{a, b} p:
      Base64.decode.go(t, B64.tok(h, alpha), D3{a, b, n}, p, acc, 1n+off, alpha)
    case SCon{+h, t} TokVal{n} D3{a, b, c} p:
      Base64.decode.go(
        t, B64.tok(h, alpha), D0{}, p, B64.emit4(a, b, c, n, acc), 1n+off, alpha
      )
    case SCon{+h, t} TokPad{} D2{a, b} B64Pad{}:
      Base64.decode.go(t, B64.tok(h, alpha), Eq1{a, b}, B64Pad{}, acc, 1n+off, alpha)
    case SCon{+h, t} TokPad{} D3{a, b, c} B64Pad{}:
      Base64.decode.go(
        t, B64.tok(h, alpha), PadEnd{}, B64Pad{},
        B64.emit2(a, b, c, acc), 1n+off, alpha
      )
    case SCon{+h, t} TokPad{} Eq1{a, b} B64Pad{}:
      Base64.decode.go(
        t, B64.tok(h, alpha), PadEnd{}, B64Pad{},
        Con{B64.byte1(a, b), acc}, 1n+off, alpha
      )
    case SCon{_, _} TokPad{} D0{} _:
      Fail{InvalidChar{off, '='}}
    case SCon{_, _} TokPad{} D1{_} _:
      Fail{InvalidChar{off, '='}}
    case SCon{_, _} TokPad{} PadEnd{} _:
      Fail{InvalidChar{off, '='}}
    case SCon{_, _} TokVal{_} Eq1{_, _} _:
      Fail{InvalidChar{off, '='}}
    case SCon{_, _} TokVal{_} PadEnd{} _:
      Fail{InvalidLength{off}}
    case SCon{_, _} TokPad{} D2{_, _} B64Raw{}:
      Fail{InvalidChar{off, '='}}
    case SCon{_, _} TokPad{} D3{_, _, _} B64Raw{}:
      Fail{InvalidChar{off, '='}}
    case SCon{_, _} TokPad{} Eq1{_, _} B64Raw{}:
      Fail{InvalidChar{off, '='}}

def Base64.decode.start(
  s: String, +alpha: B64.Alpha, +pad: B64.Pad
) -> Result<&2, &2, Base64.Error, B.Bytes>:
  match s:
    case SNil{}:
      Done{B.Bytes{Nil{}}}
    case SCon{+h, t}:
      Base64.decode.go(t, B64.tok(h, alpha), D0{}, pad, Nil{}, 0n, alpha)

def Base64.decode(text: String) -> Result<&2, &2, Base64.Error, B.Bytes>:
  Base64.decode.start(text, B64Std{}, B64Pad{})

def Base64Url.decode.p(
  text: String, padded: Bool
) -> Result<&2, &2, Base64.Error, B.Bytes>:
  match padded:
    case True{}:
      Base64.decode.start(text, B64Url{}, B64Pad{})
    case False{}:
      Base64.decode.start(text, B64Url{}, B64Raw{})

def Base64Url.decode(
  text: String, padded: Bool
) -> Result<&2, &2, Base64.Error, B.Bytes>:
  Base64Url.decode.p(text, padded)

def Base64.encode_u32_list.from(
  r: Result<&2, &2, B.Bytes.Error, B.Bytes>
) -> Result<&2, &2, Base64.Error, String>:
  match r:
    case Fail{e}:
      Fail{Base64.from_bytes_err(e)}
    case Done{b}:
      Done{Base64.encode(b)}

def Base64.encode_u32_list(
  values: List<&2, U32>
) -> Result<&2, &2, Base64.Error, String>:
  Base64.encode_u32_list.from(B.Bytes.from_u32_list(values))

def Base64Url.encode_u32_list.from(
  r: Result<&2, &2, B.Bytes.Error, B.Bytes>, padded: Bool
) -> Result<&2, &2, Base64.Error, String>:
  match r:
    case Fail{e}:
      Fail{Base64.from_bytes_err(e)}
    case Done{b}:
      Done{Base64Url.encode(b, padded)}

def Base64Url.encode_u32_list(
  values: List<&2, U32>, padded: Bool
) -> Result<&2, &2, Base64.Error, String>:
  Base64Url.encode_u32_list.from(B.Bytes.from_u32_list(values), padded)

def Base64.decode_u32_list.from(
  r: Result<&2, &2, Base64.Error, B.Bytes>
) -> Result<&2, &2, Base64.Error, List<&2, U32>>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{b}:
      Done{B.Bytes.to_u32_list(b)}

def Base64.decode_u32_list(
  text: String
) -> Result<&2, &2, Base64.Error, List<&2, U32>>:
  Base64.decode_u32_list.from(Base64.decode(text))

def Base64Url.decode_u32_list(
  text: String, padded: Bool
) -> Result<&2, &2, Base64.Error, List<&2, U32>>:
  Base64.decode_u32_list.from(Base64Url.decode(text, padded))
