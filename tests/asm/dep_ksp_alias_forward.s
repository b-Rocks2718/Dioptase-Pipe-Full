  .origin 0x400
_start:
  # Kernel-mode non-crmv writes to r31 must target ksp and forward as ksp.
  movi r31, 0x200
  add  r2, r31, 1

  # crmv writes architectural r31 (no alias). A following non-crmv read of
  # r31 must still see ksp, not the just-written architectural r31 value.
  movi r4, 0x55
  crmv epc, r4
  crmv r31, epc
  add  r3, r31, 1

  add  r1, r2, r3
  mode halt
