  .kernel

  add  r5 r0 10
  add  r7 r0 11
  add  r3 r5 r7
  add  r3 r3 r3
  add  r3 r3 -4
  mode halt     # should return 38 = 0x26
