import Base
import ../hex.bend as H

def HexTest.ok(name: String, pass: Bool) -> IO(Unit):
  match pass:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, name)

def HexTest.all4(a: Bool, b: Bool, c: Bool, d: Bool) -> Bool:
  Bool.and(a, Bool.and(b, Bool.and(c, d)))

def HexTest.str_done(
  name: String, r: Result<&2, &2, H.Hex.Error, String>, want: String
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{s}:
      HexTest.ok(name, String.eq(s, want))

def HexTest.is_fail(
  name: String, r: Result<&2, &2, H.Hex.Error, String>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def HexTest.is_fail_list(
  name: String, r: Result<&2, &2, H.Hex.Error, List<&2, U32>>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def HexTest.list_nil2(name: String, xs: List<&2, U32>) -> IO(Unit):
  match xs:
    case Nil{}:
      IO.pure(Unit, Unit{})
    case Con{_, _}:
      IO.die(Unit, 1, name)

def HexTest.list_nil(
  name: String, r: Result<&2, &2, H.Hex.Error, List<&2, U32>>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{xs}:
      HexTest.list_nil2(name, xs)

def HexTest.golden_list(name: String, xs: List<&2, U32>) -> IO(Unit):
  match xs:
    case Con{a, Con{b, Con{c, Con{d, Nil{}}}}}:
      HexTest.ok(
        name,
        HexTest.all4(
          U32.is_eq(a, 0), U32.is_eq(b, 1), U32.is_eq(c, 254), U32.is_eq(d, 255)
        )
      )
    case _:
      IO.die(Unit, 1, name)

def HexTest.golden_dec(
  name: String, r: Result<&2, &2, H.Hex.Error, List<&2, U32>>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{xs}:
      HexTest.golden_list(name, xs)

def HexTest.one_255_list(name: String, xs: List<&2, U32>) -> IO(Unit):
  match xs:
    case Con{x, Nil{}}:
      HexTest.ok(name, U32.is_eq(x, 255))
    case _:
      IO.die(Unit, 1, name)

def HexTest.one_255(
  name: String, r: Result<&2, &2, H.Hex.Error, List<&2, U32>>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{xs}:
      HexTest.one_255_list(name, xs)

def HexTest.fail_256_err(name: String, e: H.Hex.Error) -> IO(Unit):
  match e:
    case H.InvalidByte{i, v}:
      HexTest.ok(name, Bool.and(Nat.is_eq(i, 0n), U32.is_eq(v, 256)))
    case H.InvalidChar{_, _}:
      IO.die(Unit, 1, name)
    case H.OddLength{_}:
      IO.die(Unit, 1, name)

def HexTest.fail_256(
  name: String, r: Result<&2, &2, H.Hex.Error, String>
) -> IO(Unit):
  match r:
    case Done{_}:
      IO.die(Unit, 1, name)
    case Fail{e}:
      HexTest.fail_256_err(name, e)

def HexTest.roundtrip_dec(
  +name: String, want: String, r: Result<&2, &2, H.Hex.Error, List<&2, U32>>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{xs}:
      HexTest.str_done(name, H.Hex.encode_u32_list(xs, H.HexLower{}), want)

def HexTest.roundtrip_enc(
  +name: String, r: Result<&2, &2, H.Hex.Error, String>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{+s}:
      HexTest.roundtrip_dec(name, s, H.Hex.decode_u32_list(s))

def HexTest.roundtrip(+name: String, xs: List<&2, U32>) -> IO(Unit):
  HexTest.roundtrip_enc(name, H.Hex.encode_u32_list(xs, H.HexLower{}))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- HexTest.str_done(
      "empty_enc", H.Hex.encode_u32_list(Nil{}, H.HexLower{}), ""
    )
    Unit <- HexTest.list_nil("empty_dec", H.Hex.decode_u32_list(""))
    Unit <- HexTest.str_done(
      "golden_enc",
      H.Hex.encode_u32_list([0, 1, 254, 255], H.HexLower{}),
      "0001feff"
    )
    Unit <- HexTest.str_done(
      "golden_upper",
      H.Hex.encode_u32_list([0, 1, 254, 255], H.HexUpper{}),
      "0001FEFF"
    )
    Unit <- HexTest.golden_dec(
      "golden_dec", H.Hex.decode_u32_list("0001feff")
    )
    Unit <- HexTest.one_255("dec_FF", H.Hex.decode_u32_list("FF"))
    Unit <- HexTest.one_255("dec_Ff", H.Hex.decode_u32_list("Ff"))
    Unit <- HexTest.fail_256(
      "byte_256", H.Hex.encode_u32_list([256], H.HexLower{})
    )
    Unit <- HexTest.is_fail_list("odd", H.Hex.decode_u32_list("0"))
    Unit <- HexTest.is_fail_list("0g", H.Hex.decode_u32_list("0g"))
    Unit <- HexTest.is_fail_list("0x", H.Hex.decode_u32_list("0x00"))
    Unit <- HexTest.is_fail_list("space", H.Hex.decode_u32_list("00 01"))
    Unit <- HexTest.roundtrip("rt_empty", Nil{})
    Unit <- HexTest.roundtrip("rt_golden", [0, 1, 254, 255])
    Unit <- HexTest.roundtrip("rt_aa", [170])
    IO.print("ok")
