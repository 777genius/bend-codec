import Base
import ../bytes.bend as B
import ../utf8.bend as U
import ../hex.bend as H

def Readme.chain(
  r: Result<&2, &2, U.Utf8.Error, B.Bytes>
) -> String:
  match r:
    case Fail{_}:
      "fail"
    case Done{b}:
      H.Hex.encode(b, H.HexLower{})

def main() -> IO(Unit):
  IO.print(Readme.chain(U.Utf8.encode("hi")))
