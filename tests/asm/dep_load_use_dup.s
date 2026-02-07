  .origin 0x400
_start:
  lw r2, [A]
  add r3, r2, r2
  mov r1, r3
  mode halt

A:
  .fill 7
