import Base

type Bytes.Error is Data:
  InvalidByte{index: Nat, value: U32}

type Bytes is Data:
  Bytes{data: List<&2, U32>}

def Bytes.ok_byte(x: U32) -> Bool:
  U32.is_le(x, 255)

def Bytes.from_u32_list.go(
  xs: List<&2, U32>, acc: List<&2, U32>, i: Nat, ok: Bool, +h: U32
) -> Result<&2, &2, Bytes.Error, Bytes>:
  match xs ok:
    case _ False{}:
      Fail{InvalidByte{i, h}}
    case Nil{} True{}:
      Done{Bytes{List.reverse(&2, U32, Con{h, acc})}}
    case Con{+hh, t} True{}:
      Bytes.from_u32_list.go(t, Con{h, acc}, 1n+i, Bytes.ok_byte(hh), hh)

def Bytes.from_u32_list.start(
  xs: List<&2, U32>
) -> Result<&2, &2, Bytes.Error, Bytes>:
  match xs:
    case Nil{}:
      Done{Bytes{Nil{}}}
    case Con{+h, t}:
      Bytes.from_u32_list.go(t, Nil{}, 0n, Bytes.ok_byte(h), h)

def Bytes.from_u32_list(
  values: List<&2, U32>
) -> Result<&2, &2, Bytes.Error, Bytes>:
  Bytes.from_u32_list.start(values)

def Bytes.to_u32_list(b: Bytes) -> List<&2, U32>:
  match b:
    case Bytes{data}:
      data
