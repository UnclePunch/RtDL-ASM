#To be inserted at 80522858
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
lwz reg,0x4(Buffer)
lwz reg,0x8(reg)
.endm

.macro GetState reg
addi reg,reg,788
.endm

#Functions
.set onSetNextStateFactory,0x80708824
.set UtilStateFactory,0x8025dd68

#Struct offsets
.set Inputs,0x4

#Registers
.set Buffer,31
.set State,30

#Check if last interrupt succeeded
  cmpwi r3,0
  bne Exit
#Check For Airdodge
  mr  r3,r29
  branchl r12,0x800dc20c

Exit:
  cmpwi r3,0
