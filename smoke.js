import H from "./hex.bend";

function list(xs) {
  return xs.reduceRight((t, h) => ({ $: "Con", head: h, tail: t }), { $: "Nil" });
}

const r = H["Hex.encode_u32_list"](list([0, 1, 254, 255]), { $: "HexLower" });
document.body.textContent = r?.$ === "Done" ? r.value : JSON.stringify(r);
