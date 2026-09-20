import Base
import ../base64.bend as B64

def Readme.from_result(
  r: Result<&2, &2, B64.Base64.Error, String>
) -> String:
  match r:
    case Done{s}:
      s
    case Fail{_}:
      "fail"

def main() -> IO(Unit):
  IO.print(
    Readme.from_result(B64.Base64.encode_u32_list([0, 1, 254, 255]))
  )
