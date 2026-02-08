  .define EXIT_IVT 0x4

  .origin 0x400

  movi r10, EXIT_IVT
  adpc r11, EXIT
  swa  r11, [r10]

_start:
  # cr6 should be EFG and preserve general control-register writes.
  movi r2, 0x12345678
  mov efg, r2
  mov r3, efg
  sub r3, r3, r2

  # cr9 is CID and must remain read-only 0 for now.
  movi r4, 0x89ABCDEF
  mov cid, r4
  mov r5, cid

  # Return non-zero if either invariant failed.
  or r1, r3, r5
  sys EXIT

EXIT:
  mode halt
