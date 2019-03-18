#To be inserted at 8052a544

.set Buffer,3
.set Player,27

.macro GetModel reg
lwz \reg,176(Buffer)
.endm

lwz Buffer,0x4(Player)
GetModel r4
li  r3,0x1
stb r3,0x2E61(r4)
mr r3,Player
