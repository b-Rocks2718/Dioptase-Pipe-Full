  .define EXIT_IVT 0x4
  
  .origin 0x400

  # register EXIT handler
  movi r1, EXIT_IVT
  adpc r2, EXIT
  swa  r2, [r1]

  add  r5 r0 10
  add  r7 r0 11
  add  r3 r5 r7
  add  r3 r3 r3
  add  r1 r3 -4
  sys  EXIT

EXIT:
  mode halt     # should return 38 = 0x26
