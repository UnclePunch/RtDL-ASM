#To be inserted at 801a3c7c
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
.set KirbyScriptNum,0x1BC

#Check if Kirby (only have extra actions for him) use 804ebbdc, 804ebbe4, 804ebbec, 804ebbf4
  load r3,0x808ad148
  cmpw r3,r7
  bne Original

#Check if requested script is greater than
  cmpwi r4,KirbyScriptNum
  blt Original

#Get Custom Script Name
  subi r3,r4,KirbyScriptNum
  bl  KirbyScriptTable
  mflr r4
  bl  GetScriptNameFromTable
  mr  r6,r3

  b Exit

###############################
GetScriptNameFromTable:
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

GetScriptNameFromTable_Loop:
#Check if we are up to the correct ScriptTable
  cmpw ID,LoopCount
  beq GetScriptNameFromTable_Exit
#Get string length
  mr  r3,ScriptTable
  branchl r12,strlen
#Add to current ScriptTable pointer
  add ScriptTable,ScriptTable,r3
  addi ScriptTable,ScriptTable,1
#Inc Loop Count
  addi LoopCount,LoopCount,1
  b GetScriptNameFromTable_Loop

GetScriptNameFromTable_Exit:
  mr  r3,ScriptTable
  restore
  blr

###############################

KirbyScriptTable:
blrl
.string "Common.AnimScript.AirDodge.Exec()"         #State 0x1BC
.string "Common.AnimScript.Placeholder.Exec()"      #State 0x1BD
.align 2

###############################

Original:
  lwz	r6, 0 (r31)

Exit:
  mr  r3,r29
  mr  r4,r30
  lwz r7,0x0(r3)
