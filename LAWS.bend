import Base
import ./bytes.bend as B
import ./hex.bend as H
import ./base64.bend as B64
import ./utf8.bend as U

law encode_empty:
  {H.Hex.encode(B.Bytes{Nil{}}, H.HexLower{}) == "" : String}

law decode_empty:
  {
    H.Hex.decode("") == Done{B.Bytes{Nil{}}}
    : Result<&2, &2, H.Hex.Error, B.Bytes>
  }

law encode_golden:
  {
    H.Hex.encode_u32_list([0, 1, 254, 255], H.HexLower{}) == Done{"0001feff"}
    : Result<&2, &2, H.Hex.Error, String>
  }

law decode_golden:
  {
    H.Hex.decode_u32_list("0001feff") == Done{[0, 1, 254, 255]}
    : Result<&2, &2, H.Hex.Error, List<&2, U32>>
  }

law encode_aa:
  {
    H.Hex.encode_u32_list([170], H.HexLower{}) == Done{"aa"}
    : Result<&2, &2, H.Hex.Error, String>
  }

law decode_aa:
  {
    H.Hex.decode_u32_list("aa") == Done{[170]}
    : Result<&2, &2, H.Hex.Error, List<&2, U32>>
  }

law decode_FF:
  {
    H.Hex.decode_u32_list("FF") == Done{[255]}
    : Result<&2, &2, H.Hex.Error, List<&2, U32>>
  }

law nibble_0:
  {H.Hex.nibble('0') == Some{0} : Maybe<&2, U32>}

law nibble_f:
  {H.Hex.nibble('f') == Some{15} : Maybe<&2, U32>}

law nibble_F:
  {H.Hex.nibble('F') == Some{15} : Maybe<&2, U32>}

law nibble_g:
  {H.Hex.nibble('g') == None{} : Maybe<&2, U32>}

law b64_encode_empty:
  {B64.Base64.encode(B.Bytes{Nil{}}) == "" : String}

law b64_decode_empty:
  {
    B64.Base64.decode("") == Done{B.Bytes{Nil{}}}
    : Result<&2, &2, B64.Base64.Error, B.Bytes>
  }

law b64_encode_golden:
  {
    B64.Base64.encode_u32_list([0, 1, 254, 255]) == Done{"AAH+/w=="}
    : Result<&2, &2, B64.Base64.Error, String>
  }

law b64_decode_golden:
  {
    B64.Base64.decode_u32_list("AAH+/w==") == Done{[0, 1, 254, 255]}
    : Result<&2, &2, B64.Base64.Error, List<&2, U32>>
  }

law b64url_encode_golden:
  {
    B64.Base64Url.encode_u32_list([0, 1, 254, 255], False{}) == Done{"AAH-_w"}
    : Result<&2, &2, B64.Base64.Error, String>
  }

law utf8_empty:
  {
    U.Utf8.encode("") == Done{B.Bytes{Nil{}}}
    : Result<&2, &2, U.Utf8.Error, B.Bytes>
  }

law utf8_A:
  {
    U.Utf8.encode("A") == Done{B.Bytes{Con{65, Nil{}}}}
    : Result<&2, &2, U.Utf8.Error, B.Bytes>
  }
