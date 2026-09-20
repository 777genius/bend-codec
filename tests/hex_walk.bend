import Base
import ../hex.bend as H

def HexWalk.fill.go(+n: Nat, +x: U32, acc: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      acc
    case 1n++p:
      HexWalk.fill.go(p, x, Con{x, acc})

def HexWalk.fill(n: Nat, x: U32) -> List<&2, U32>:
  HexWalk.fill.go(n, x, Nil{})

def HexWalk.n20k() -> Nat:
  Nat.mul(200n, 100n)

def HexWalk.str_eq(a: String, b: String, same: Bool) -> Bool:
  match a b same:
    case _ _ False{}:
      False{}
    case SNil{} SNil{} True{}:
      True{}
    case SCon{ha, ta} SCon{hb, tb} True{}:
      HexWalk.str_eq(ta, tb, Char.is_eq(ha, hb))
    case SNil{} SCon{_, _} True{}:
      False{}
    case SCon{_, _} SNil{} True{}:
      False{}

def HexWalk.ok(name: String, pass: Bool) -> IO(Unit):
  match pass:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, name)

def HexWalk.str_done(
  name: String, r: Result<&2, &2, H.Hex.Error, String>, want: String
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{s}:
      HexWalk.ok(name, HexWalk.str_eq(s, want, True{}))

def HexWalk.roundtrip_dec(
  +name: String, want: String, r: Result<&2, &2, H.Hex.Error, List<&2, U32>>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{xs}:
      HexWalk.str_done(name, H.Hex.encode_u32_list(xs, H.HexLower{}), want)

def HexWalk.roundtrip_enc(
  +name: String, r: Result<&2, &2, H.Hex.Error, String>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{+s}:
      HexWalk.roundtrip_dec(name, s, H.Hex.decode_u32_list(s))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- HexWalk.roundtrip_enc(
      "walk_20k",
      H.Hex.encode_u32_list(HexWalk.fill(HexWalk.n20k(), 171), H.HexLower{})
    )
    IO.print("ok")
