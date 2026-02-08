  .origin 0x400
_start:
  movi r2, 0x1234

  # Back-to-back control-register dependencies must forward the newest value.
  crmv epc, r2
  crmv efg, epc
  crmv r3, efg

  add  r1, r3, 1
  mode halt
