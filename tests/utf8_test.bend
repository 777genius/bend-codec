import Base
import ../bytes.bend as B
import ../utf8.bend as U

def Utf8Test.ok(name: String, pass: Bool) -> IO(Unit):
  match pass:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, name)

def Utf8Test.list_eq(
  a: List<&2, U32>, b: List<&2, U32>, ready: Bool
) -> Bool:
  match a b ready:
    case _ _ False{}:
      False{}
    case Nil{} Nil{} True{}:
      True{}
    case Nil{} Con{_, _} True{}:
      False{}
    case Con{_, _} Nil{} True{}:
      False{}
    case Con{+h1, t1} Con{+h2, t2} True{}:
      Utf8Test.list_eq(t1, t2, U32.is_eq(h1, h2))

def Utf8Test.bytes_r(
  r: Result<&2, &2, B.Bytes.Error, B.Bytes>
) -> B.Bytes:
  match r:
    case Fail{_}:
      B.Bytes{Nil{}}
    case Done{b}:
      b

def Utf8Test.bytes(xs: List<&2, U32>) -> B.Bytes:
  Utf8Test.bytes_r(B.Bytes.from_u32_list(xs))

def Utf8Test.enc_r(
  name: String, want: List<&2, U32>, r: Result<&2, &2, U.Utf8.Error, B.Bytes>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{b}:
      Utf8Test.ok(
        name, Utf8Test.list_eq(B.Bytes.to_u32_list(b), want, True{})
      )

def Utf8Test.enc_ok(
  name: String, text: String, want: List<&2, U32>
) -> IO(Unit):
  Utf8Test.enc_r(name, want, U.Utf8.encode(text))

def Utf8Test.dec_r(
  name: String, want: String, r: Result<&2, &2, U.Utf8.Error, String>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{s}:
      Utf8Test.ok(name, String.eq(s, want))

def Utf8Test.dec_ok(
  name: String, xs: List<&2, U32>, want: String
) -> IO(Unit):
  Utf8Test.dec_r(name, want, U.Utf8.decode(Utf8Test.bytes(xs)))

def Utf8Test.dec_fail_r(
  name: String, r: Result<&2, &2, U.Utf8.Error, String>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def Utf8Test.dec_fail(name: String, xs: List<&2, U32>) -> IO(Unit):
  Utf8Test.dec_fail_r(name, U.Utf8.decode(Utf8Test.bytes(xs)))

def Utf8Test.eacute() -> String:
  SCon{Char.from_u32(233), SNil{}}

def Utf8Test.euro() -> String:
  SCon{Char.from_u32(8364), SNil{}}

def Utf8Test.gothic() -> String:
  SCon{Char.from_u32(66376), SNil{}}

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Utf8Test.enc_ok("enc_empty", "", Nil{})
    Unit <- Utf8Test.dec_ok("dec_empty", Nil{}, "")
    Unit <- Utf8Test.enc_ok("enc_A", "A", [65])
    Unit <- Utf8Test.dec_ok("dec_A", [65], "A")
    Unit <- Utf8Test.enc_ok("enc_hi", "hi", [104, 105])
    Unit <- Utf8Test.dec_ok("dec_hi", [104, 105], "hi")
    Unit <- Utf8Test.enc_ok("enc_e", Utf8Test.eacute(), [195, 169])
    Unit <- Utf8Test.dec_ok("dec_e", [195, 169], Utf8Test.eacute())
    Unit <- Utf8Test.enc_ok("enc_euro", Utf8Test.euro(), [226, 130, 172])
    Unit <- Utf8Test.dec_ok("dec_euro", [226, 130, 172], Utf8Test.euro())
    Unit <- Utf8Test.enc_ok(
      "enc_gothic", Utf8Test.gothic(), [240, 144, 141, 136]
    )
    Unit <- Utf8Test.dec_ok(
      "dec_gothic", [240, 144, 141, 136], Utf8Test.gothic()
    )
    Unit <- Utf8Test.dec_fail("overlong", [192, 128])
    Unit <- Utf8Test.dec_fail("trunc", [195])
    Unit <- Utf8Test.dec_fail("ff", [255])
    Unit <- Utf8Test.dec_fail("sur", [237, 160, 128])
    IO.print("ok")
