#To be inserted at 804e9f40
.macro branchl reg, address
lis \reg, \address @h
ori \reg,\reg,\address @l
mtctr \reg
bctrl
.endm

.macro branch reg, address
lis \reg, \address @h
ori \reg,\reg,\address @l
mtctr \reg
bctr
.endm

.macro load reg, address
lis \reg, \address @h
ori \reg, \reg, \address @l
.endm

.macro backup
mflr r0
stw r0, 0x4(r1)
stwu	r1,-0x100(r1)	# make space for 12 registers
stmw  r20,0x8(r1)
.endm

.macro restore
lmw  r20,0x8(r1)
lwz r0, 0x104(r1)
addi	r1,r1,0x100	# release the space
mtlr r0
.endm

.macro GetInputs reg
lwz \reg,224(Buffer)
lwz \reg,0x8(\reg)
.endm

.macro GetHeldInputs reg
lwz \reg,224(Buffer)
lwz \reg,0x4(\reg)
.endm

.macro GetState reg
lwz \reg,792(Buffer)
.endm

.macro GetMove reg
lwz \reg,168(Buffer)
.endm

.macro GetModel reg
lwz \reg,176(Buffer)
.endm

.macro GetMapColl reg
lwz \reg,208(Buffer)
.endm

.macro GetInvincible reg
lwz \reg,296(Buffer)
.endm

.macro GetScript reg
lwz \reg,488(Buffer)
.endm

.macro GetObjColl reg
lwz \reg,240(Buffer)
.endm

.macro GetPlayer reg
GetState \reg
lwz \reg,0x8(\reg)
.endm

.set Buffer,30

#Check If Grounded
  GetMapColl r3
  lbz r3,0x48(r3)
  cmpwi r3,0x0
  beq Exit
#Set Airdodge Flag
  GetPlayer r4
  li  r3,0
  stb r3,0x79(r4)

Exit:
#Original
  addi	r3, r30, 396
