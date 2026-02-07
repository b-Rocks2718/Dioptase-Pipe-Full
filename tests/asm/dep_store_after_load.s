  .origin 0x400
_start:
  lw r2, [A]
  sw r2, [B]
  lw r3, [B]
  mov r1, r3
  mode halt

A:
  .fill 0x12345678
B:
  .fill 0
