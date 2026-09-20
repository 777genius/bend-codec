import Base
import ../base64.bend as B64

def B64Test.ok(name: String, pass: Bool) -> IO(Unit):
  match pass:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, name)

def B64Test.all4(a: Bool, b: Bool, c: Bool, d: Bool) -> Bool:
  Bool.and(a, Bool.and(b, Bool.and(c, d)))

def B64Test.str_done(
  name: String, r: Result<&2, &2, B64.Base64.Error, String>, want: String
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{s}:
      B64Test.ok(name, String.eq(s, want))

def B64Test.is_fail_list(
  name: String, r: Result<&2, &2, B64.Base64.Error, List<&2, U32>>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def B64Test.list_nil2(name: String, xs: List<&2, U32>) -> IO(Unit):
  match xs:
    case Nil{}:
      IO.pure(Unit, Unit{})
    case Con{_, _}:
      IO.die(Unit, 1, name)

def B64Test.list_nil(
  name: String, r: Result<&2, &2, B64.Base64.Error, List<&2, U32>>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{xs}:
      B64Test.list_nil2(name, xs)

def B64Test.golden_list(name: String, xs: List<&2, U32>) -> IO(Unit):
  match xs:
    case Con{a, Con{b, Con{c, Con{d, Nil{}}}}}:
      B64Test.ok(
        name,
        B64Test.all4(
          U32.is_eq(a, 0), U32.is_eq(b, 1), U32.is_eq(c, 254), U32.is_eq(d, 255)
        )
      )
    case _:
      IO.die(Unit, 1, name)

def B64Test.golden_dec(
  name: String, r: Result<&2, &2, B64.Base64.Error, List<&2, U32>>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{xs}:
      B64Test.golden_list(name, xs)

def B64Test.one_list(name: String, xs: List<&2, U32>, want: U32) -> IO(Unit):
  match xs:
    case Con{x, Nil{}}:
      B64Test.ok(name, U32.is_eq(x, want))
    case _:
      IO.die(Unit, 1, name)

def B64Test.one(
  name: String, r: Result<&2, &2, B64.Base64.Error, List<&2, U32>>, want: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{xs}:
      B64Test.one_list(name, xs, want)

def B64Test.roundtrip_dec(
  +name: String, want: String,
  r: Result<&2, &2, B64.Base64.Error, List<&2, U32>>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{xs}:
      B64Test.str_done(name, B64.Base64.encode_u32_list(xs), want)

def B64Test.roundtrip_enc(
  +name: String, r: Result<&2, &2, B64.Base64.Error, String>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{+s}:
      B64Test.roundtrip_dec(name, s, B64.Base64.decode_u32_list(s))

def B64Test.roundtrip(+name: String, xs: List<&2, U32>) -> IO(Unit):
  B64Test.roundtrip_enc(name, B64.Base64.encode_u32_list(xs))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- B64Test.str_done("empty_enc", B64.Base64.encode_u32_list(Nil{}), "")
    Unit <- B64Test.list_nil("empty_dec", B64.Base64.decode_u32_list(""))
    Unit <- B64Test.str_done(
      "golden_enc", B64.Base64.encode_u32_list([0, 1, 254, 255]), "AAH+/w=="
    )
    Unit <- B64Test.str_done(
      "golden_url",
      B64.Base64Url.encode_u32_list([0, 1, 254, 255], False{}),
      "AAH-_w"
    )
    Unit <- B64Test.str_done(
      "golden_url_pad",
      B64.Base64Url.encode_u32_list([0, 1, 254, 255], True{}),
      "AAH-_w=="
    )
    Unit <- B64Test.golden_dec(
      "golden_dec", B64.Base64.decode_u32_list("AAH+/w==")
    )
    Unit <- B64Test.golden_dec(
      "golden_url_dec", B64.Base64Url.decode_u32_list("AAH-_w", False{})
    )
    Unit <- B64Test.str_done(
      "enc_0", B64.Base64.encode_u32_list([0]), "AA=="
    )
    Unit <- B64Test.str_done(
      "enc_01", B64.Base64.encode_u32_list([0, 1]), "AAE="
    )
    Unit <- B64Test.one("dec_Zg", B64.Base64.decode_u32_list("Zg=="), 102)
    Unit <- B64Test.is_fail_list("zh", B64.Base64.decode_u32_list("Zh=="))
    Unit <- B64Test.is_fail_list("space", B64.Base64.decode_u32_list("AAE= "))
    Unit <- B64Test.is_fail_list("mix", B64.Base64.decode_u32_list("AAH-_w=="))
    Unit <- B64Test.is_fail_list("mid", B64.Base64.decode_u32_list("AA==AA=="))
    Unit <- B64Test.is_fail_list("short", B64.Base64.decode_u32_list("A"))
    Unit <- B64Test.is_fail_list("no_pad", B64.Base64.decode_u32_list("AA"))
    Unit <- B64Test.roundtrip("rt_empty", Nil{})
    Unit <- B64Test.roundtrip("rt_golden", [0, 1, 254, 255])
    Unit <- B64Test.roundtrip("rt_0", [0])
    Unit <- B64Test.roundtrip("rt_01", [0, 1])
    IO.print("ok")
