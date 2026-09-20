import Base
import ./bytes.bend as B

type Utf8.Error is Data:
  Truncated{index: Nat}
  InvalidByte{index: Nat, value: U32}
  Overlong{index: Nat}
  Surrogate{index: Nat}
  OutOfRange{index: Nat, value: U32}

type Utf8.Acc is Data:
  AccOk{xs: List<&2, U32>}
  AccErr{e: Utf8.Error}

type Utf8.DS is Data:
  DLead{}
  D2{b0: U32}
  D3{b0: U32}
  D3b{b0: U32, b1: U32}
  D4{b0: U32}
  D4b{b0: U32, b1: U32}
  D4c{b0: U32, b1: U32, b2: U32}
  DErr{e: Utf8.Error}

def Utf8.is_cont(+b: U32) -> Bool:
  Bool.and(U32.is_ge(b, 128), U32.is_le(b, 191))

def Utf8.is_sur(+cp: U32) -> Bool:
  Bool.and(U32.is_ge(cp, 55296), U32.is_le(cp, 57343))

def Utf8.low6(b: U32) -> U32:
  U32.and(b, 63)

def Utf8.cp2(+b0: U32, +b1: U32) -> U32:
  U32.add(U32.shln(U32.and(b0, 31), 6n), Utf8.low6(b1))

def Utf8.cp3(+b0: U32, +b1: U32, +b2: U32) -> U32:
  U32.add(
    U32.shln(U32.and(b0, 15), 12n),
    U32.add(U32.shln(Utf8.low6(b1), 6n), Utf8.low6(b2))
  )

def Utf8.cp4(+b0: U32, +b1: U32, +b2: U32, +b3: U32) -> U32:
  U32.add(
    U32.shln(U32.and(b0, 7), 18n),
    U32.add(
      U32.shln(Utf8.low6(b1), 12n),
      U32.add(U32.shln(Utf8.low6(b2), 6n), Utf8.low6(b3))
    )
  )

def Utf8.bad_cp.sur(sur: Bool) -> Maybe<&2, Utf8.Error>:
  match sur:
    case True{}:
      Some{Surrogate{0n}}
    case False{}:
      None{}

def Utf8.bad_cp.over(over: Bool, sur: Bool) -> Maybe<&2, Utf8.Error>:
  match over:
    case True{}:
      Some{Overlong{0n}}
    case False{}:
      Utf8.bad_cp.sur(sur)

def Utf8.bad_cp.big(
  +cp: U32, big: Bool, over: Bool, sur: Bool
) -> Maybe<&2, Utf8.Error>:
  match big:
    case True{}:
      Some{OutOfRange{0n, cp}}
    case False{}:
      Utf8.bad_cp.over(over, sur)

def Utf8.bad_cp(+cp: U32, min: U32) -> Maybe<&2, Utf8.Error>:
  Utf8.bad_cp.big(
    cp, U32.is_gt(cp, 1114111), U32.is_lt(cp, min), Utf8.is_sur(cp)
  )

def Utf8.fix_idx(e: Utf8.Error, i: Nat) -> Utf8.Error:
  match e:
    case Truncated{_}:
      Truncated{i}
    case InvalidByte{_, v}:
      InvalidByte{i, v}
    case Overlong{_}:
      Overlong{i}
    case Surrogate{_}:
      Surrogate{i}
    case OutOfRange{_, v}:
      OutOfRange{i, v}

def Utf8.st_cp.e(
  +cp: U32, i: Nat, e: Maybe<&2, Utf8.Error>
) -> Utf8.DS:
  match e:
    case None{}:
      DLead{}
    case Some{err}:
      DErr{Utf8.fix_idx(err, i)}

def Utf8.st_cp(+cp: U32, i: Nat, min: U32) -> Utf8.DS:
  Utf8.st_cp.e(cp, i, Utf8.bad_cp(cp, min))

def Utf8.push_cp.e(
  +cp: U32, acc: String, e: Maybe<&2, Utf8.Error>
) -> String:
  match e:
    case None{}:
      SCon{Char.from_u32(cp), acc}
    case Some{_}:
      acc

def Utf8.push_cp(+cp: U32, acc: String, min: U32) -> String:
  Utf8.push_cp.e(cp, acc, Utf8.bad_cp(cp, min))

def Utf8.st_cont.ok(
  +b: U32, i: Nat, next: Utf8.DS, ok: Bool
) -> Utf8.DS:
  match ok:
    case False{}:
      DErr{InvalidByte{i, b}}
    case True{}:
      next

def Utf8.st_cont(+b: U32, i: Nat, next: Utf8.DS) -> Utf8.DS:
  Utf8.st_cont.ok(b, i, next, Utf8.is_cont(b))

def Utf8.class_lead.e(+h: U32, i: Nat, four: Bool) -> Utf8.DS:
  match four:
    case True{}:
      D4{h}
    case False{}:
      DErr{InvalidByte{i, h}}

def Utf8.class_lead.d(+h: U32, i: Nat, three: Bool) -> Utf8.DS:
  match three:
    case True{}:
      D3{h}
    case False{}:
      Utf8.class_lead.e(h, i, U32.is_le(h, 247))

def Utf8.class_lead.c(
  +h: U32, i: Nat, two: Bool, three: Bool
) -> Utf8.DS:
  match two:
    case True{}:
      D2{h}
    case False{}:
      Utf8.class_lead.d(h, i, three)

def Utf8.class_lead.b(+h: U32, i: Nat, cont: Bool) -> Utf8.DS:
  match cont:
    case True{}:
      DErr{InvalidByte{i, h}}
    case False{}:
      Utf8.class_lead.c(h, i, U32.is_le(h, 223), U32.is_le(h, 239))

def Utf8.class_lead.a(+h: U32, i: Nat, ascii: Bool) -> Utf8.DS:
  match ascii:
    case True{}:
      DLead{}
    case False{}:
      Utf8.class_lead.b(h, i, U32.is_le(h, 191))

def Utf8.class_lead(+h: U32, i: Nat) -> Utf8.DS:
  Utf8.class_lead.a(h, i, U32.is_le(h, 127))

def Utf8.ascii_acc(+h: U32, acc: String, ascii: Bool) -> String:
  match ascii:
    case True{}:
      SCon{Char.from_u32(h), acc}
    case False{}:
      acc

def Utf8.push2.c(+b0: U32, +b1: U32, acc: String, ok: Bool) -> String:
  match ok:
    case False{}:
      acc
    case True{}:
      Utf8.push_cp(Utf8.cp2(b0, b1), acc, 128)

def Utf8.push2(+b0: U32, +b1: U32, acc: String) -> String:
  Utf8.push2.c(b0, b1, acc, Utf8.is_cont(b1))

def Utf8.after2.c(+b0: U32, +b1: U32, i: Nat, ok: Bool) -> Utf8.DS:
  match ok:
    case False{}:
      DErr{InvalidByte{i, b1}}
    case True{}:
      Utf8.st_cp(Utf8.cp2(b0, b1), i, 128)

def Utf8.after2(+b0: U32, +b1: U32, i: Nat) -> Utf8.DS:
  Utf8.after2.c(b0, b1, i, Utf8.is_cont(b1))

def Utf8.push3.c(
  +b0: U32, +b1: U32, +b2: U32, acc: String, ok: Bool
) -> String:
  match ok:
    case False{}:
      acc
    case True{}:
      Utf8.push_cp(Utf8.cp3(b0, b1, b2), acc, 2048)

def Utf8.push3(+b0: U32, +b1: U32, +b2: U32, acc: String) -> String:
  Utf8.push3.c(b0, b1, b2, acc, Utf8.is_cont(b2))

def Utf8.after3.c(
  +b0: U32, +b1: U32, +b2: U32, i: Nat, ok: Bool
) -> Utf8.DS:
  match ok:
    case False{}:
      DErr{InvalidByte{i, b2}}
    case True{}:
      Utf8.st_cp(Utf8.cp3(b0, b1, b2), i, 2048)

def Utf8.after3(+b0: U32, +b1: U32, +b2: U32, i: Nat) -> Utf8.DS:
  Utf8.after3.c(b0, b1, b2, i, Utf8.is_cont(b2))

def Utf8.push4.c(
  +b0: U32, +b1: U32, +b2: U32, +b3: U32, acc: String, ok: Bool
) -> String:
  match ok:
    case False{}:
      acc
    case True{}:
      Utf8.push_cp(Utf8.cp4(b0, b1, b2, b3), acc, 65536)

def Utf8.push4(
  +b0: U32, +b1: U32, +b2: U32, +b3: U32, acc: String
) -> String:
  Utf8.push4.c(b0, b1, b2, b3, acc, Utf8.is_cont(b3))

def Utf8.after4.c(
  +b0: U32, +b1: U32, +b2: U32, +b3: U32, i: Nat, ok: Bool
) -> Utf8.DS:
  match ok:
    case False{}:
      DErr{InvalidByte{i, b3}}
    case True{}:
      Utf8.st_cp(Utf8.cp4(b0, b1, b2, b3), i, 65536)

def Utf8.after4(
  +b0: U32, +b1: U32, +b2: U32, +b3: U32, i: Nat
) -> Utf8.DS:
  Utf8.after4.c(b0, b1, b2, b3, i, Utf8.is_cont(b3))

def Utf8.dec.go(
  xs: List<&2, U32>, st: Utf8.DS, acc: String, +i: Nat
) -> Result<&2, &2, Utf8.Error, String>:
  match xs st:
    case _ DErr{e}:
      Fail{e}
    case Nil{} DLead{}:
      Done{String.reverse(acc)}
    case Con{+h, t} DLead{}:
      Utf8.dec.go(
        t,
        Utf8.class_lead(h, i),
        Utf8.ascii_acc(h, acc, U32.is_le(h, 127)),
        1n+i
      )
    case Nil{} D2{_}:
      Fail{Truncated{i}}
    case Con{+b1, t} D2{+b0}:
      Utf8.dec.go(t, Utf8.after2(b0, b1, i), Utf8.push2(b0, b1, acc), 1n+i)
    case Nil{} D3{_}:
      Fail{Truncated{i}}
    case Con{+b1, t} D3{+b0}:
      Utf8.dec.go(
        t, Utf8.st_cont(b1, i, D3b{b0, b1}), acc, 1n+i
      )
    case Nil{} D3b{_, _}:
      Fail{Truncated{i}}
    case Con{+b2, t} D3b{+b0, +b1}:
      Utf8.dec.go(
        t, Utf8.after3(b0, b1, b2, i), Utf8.push3(b0, b1, b2, acc), 1n+i
      )
    case Nil{} D4{_}:
      Fail{Truncated{i}}
    case Con{+b1, t} D4{+b0}:
      Utf8.dec.go(
        t, Utf8.st_cont(b1, i, D4b{b0, b1}), acc, 1n+i
      )
    case Nil{} D4b{_, _}:
      Fail{Truncated{i}}
    case Con{+b2, t} D4b{+b0, +b1}:
      Utf8.dec.go(
        t, Utf8.st_cont(b2, i, D4c{b0, b1, b2}), acc, 1n+i
      )
    case Nil{} D4c{_, _, _}:
      Fail{Truncated{i}}
    case Con{+b3, t} D4c{+b0, +b1, +b2}:
      Utf8.dec.go(
        t,
        Utf8.after4(b0, b1, b2, b3, i),
        Utf8.push4(b0, b1, b2, b3, acc),
        1n+i
      )

def Utf8.decode(bytes: B.Bytes) -> Result<&2, &2, Utf8.Error, String>:
  match bytes:
    case B.Bytes{data}:
      Utf8.dec.go(data, DLead{}, SNil{}, 0n)

def Utf8.emit2(+cp: U32, acc: List<&2, U32>) -> List<&2, U32>:
  Con{
    U32.or(128, U32.and(cp, 63)),
    Con{U32.or(192, U32.shrn(cp, 6n)), acc}
  }

def Utf8.emit3(+cp: U32, acc: List<&2, U32>) -> List<&2, U32>:
  Con{
    U32.or(128, U32.and(cp, 63)),
    Con{
      U32.or(128, U32.and(U32.shrn(cp, 6n), 63)),
      Con{U32.or(224, U32.shrn(cp, 12n)), acc}
    }
  }

def Utf8.emit4(+cp: U32, acc: List<&2, U32>) -> List<&2, U32>:
  Con{
    U32.or(128, U32.and(cp, 63)),
    Con{
      U32.or(128, U32.and(U32.shrn(cp, 6n), 63)),
      Con{
        U32.or(128, U32.and(U32.shrn(cp, 12n), 63)),
        Con{U32.or(240, U32.shrn(cp, 18n)), acc}
      }
    }
  }

def Utf8.emit.e(+cp: U32, acc: List<&2, U32>, b4: Bool) -> Utf8.Acc:
  match b4:
    case True{}:
      AccOk{Utf8.emit4(cp, acc)}
    case False{}:
      AccErr{OutOfRange{0n, cp}}

def Utf8.emit.d(+cp: U32, acc: List<&2, U32>, b3: Bool) -> Utf8.Acc:
  match b3:
    case True{}:
      AccOk{Utf8.emit3(cp, acc)}
    case False{}:
      Utf8.emit.e(cp, acc, U32.is_le(cp, 1114111))

def Utf8.emit.c(
  +cp: U32, acc: List<&2, U32>, sur: Bool, b3: Bool
) -> Utf8.Acc:
  match sur:
    case True{}:
      AccErr{Surrogate{0n}}
    case False{}:
      Utf8.emit.d(cp, acc, b3)

def Utf8.emit.b(+cp: U32, acc: List<&2, U32>, b2: Bool) -> Utf8.Acc:
  match b2:
    case True{}:
      AccOk{Utf8.emit2(cp, acc)}
    case False{}:
      Utf8.emit.c(cp, acc, Utf8.is_sur(cp), U32.is_le(cp, 65535))

def Utf8.emit.a(
  +cp: U32, acc: List<&2, U32>, b1: Bool, b2: Bool
) -> Utf8.Acc:
  match b1:
    case True{}:
      AccOk{Con{cp, acc}}
    case False{}:
      Utf8.emit.b(cp, acc, b2)

def Utf8.emit(+cp: U32, acc: List<&2, U32>) -> Utf8.Acc:
  Utf8.emit.a(cp, acc, U32.is_le(cp, 127), U32.is_le(cp, 2047))

def Utf8.emit_at.fix(a: Utf8.Acc, i: Nat) -> Utf8.Acc:
  match a:
    case AccOk{xs}:
      AccOk{xs}
    case AccErr{e}:
      AccErr{Utf8.fix_idx(e, i)}

def Utf8.emit_at(cp: U32, acc: List<&2, U32>, i: Nat) -> Utf8.Acc:
  Utf8.emit_at.fix(Utf8.emit(cp, acc), i)

def Utf8.enc.go(
  s: String, acc: Utf8.Acc, +i: Nat
) -> Result<&2, &2, Utf8.Error, B.Bytes>:
  match s acc:
    case _ AccErr{e}:
      Fail{e}
    case SNil{} AccOk{xs}:
      Done{B.Bytes{List.reverse(&2, U32, xs)}}
    case SCon{h, t} AccOk{xs}:
      Utf8.enc.go(t, Utf8.emit_at(Char.to_u32(h), xs, i), 1n+i)

def Utf8.encode(text: String) -> Result<&2, &2, Utf8.Error, B.Bytes>:
  Utf8.enc.go(text, AccOk{Nil{}}, 0n)
