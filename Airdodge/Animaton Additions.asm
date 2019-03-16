#To be inserted at 801a1d98
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

.set strlen,0x80006a8c
.set KirbyAnimNum,0x22A

#Check if Kirby (only have extra actions for him) ref 8052b9f8 if wrong
  load r7,0x80728c78
  cmpw r5,r7
  bne Original

#Check if requested anim is greater than
  cmpwi r4,KirbyAnimNum
  blt Original

#Backup Pointer
  mr r31,r3

#Get Custom Anim Name
  subi r3,r4,KirbyAnimNum
  bl  KirbyAnimTable
  mflr r4
  bl  GetAnimNameFromTable

  b Exit

###############################
GetAnimNameFromTable:
.set ID,31
.set LoopCount,30
.set ScriptTable,29

backup

#Get ID
  mr ID,r3
#Get ScriptNames
  mr  ScriptTable,r4
#Init Loop Count
  li  LoopCount,0

GetAnimNameFromTable_Loop:
#Check if we are up to the correct ScriptTable
  cmpw ID,LoopCount
  beq GetAnimNameFromTable_Exit
#Get string length
  mr  r3,ScriptTable
  branchl r12,strlen
#Add to current ScriptTable pointer
  add ScriptTable,ScriptTable,r3
  addi ScriptTable,ScriptTable,1
#Inc Loop Count
  addi LoopCount,LoopCount,1
  b GetAnimNameFromTable_Loop

GetAnimNameFromTable_Exit:
  mr  r3,ScriptTable
  restore
  blr

###############################

KirbyAnimTable:
blrl
.string "Airdodge"        #Animation 0x22A
.string "Placeholder"     #Animation 0x22B
.align 2

###############################

Exit:
#Get File Start
  lwz r4,0x18(r31)
  lwz r4,0x0(r4)
#Exit
  branch r12,0x801a1dc8

Original:
  rlwinm	r0, r4, 3, 0, 28
