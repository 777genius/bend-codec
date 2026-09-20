import Base
import ../hex.bend as H

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
