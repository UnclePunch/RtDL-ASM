#To be inserted at 800dc20c
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

#Functions
.set onSetNextStateFactory,0x80708824
.set UtilStateFactory,0x8025dd68
.set MemAlloc,0x801cc2bc
.set MemFree,0x801cc318

.set AirdodgeFallFrame,22

#Registers
.set Buffer,31
.set State,30
.set Player,29

#region TryToChangeState_Airdodge
backup

  mr  Player,r3

#Get Buffer Address
  lwz Buffer,0x4(r3)

#Check if used once already
  lbz r3,0x79(Player)
  cmpwi r3,0x1
  beq EnterAirdodge_Failed

#Check for shoulder button input
  GetInputs r3
  rlwinm. r0,r3,0,24,25
  beq EnterAirdodge_Failed

#Set as used
  li  r3,1
  stb r3,0x79(Player)

#Check for pending AS change
  GetState State #remember to check this macro
  mr r3,State
  branchl r12,onSetNextStateFactory

#Unknown
  addi r3,State,0x10
  addi r4,State,144
  branchl r12,UtilStateFactory

#Store pointer to state change functions
  bl  Airdodge_FunctionPointers
  mflr r3
  stw r3,0x10(State)
  stw Buffer,0x18(State)

#Add to AS change queue
  addi r3,State,0x10
  stw r3,0xC(State)

#Place Pointers
  bl  Airdodge_FunctionPointers
  mflr r4
  bl EnterState_Airdodge
  mflr r3
  stw r3,0xC(r4)
  bl ReleaseCurrentState_Airdodge
  mflr r3
  stw r3,0x18(r4)
  bl ProcAnim_Airdodge
  mflr r3
  stw r3,0x1C(r4)
  bl ProcMove_Airdodge
  mflr r3
  stw r3,0x20(r4)
  bl ProcFixPos_Airdodge
  mflr r3
  stw r3,0x28(r4)

EnterAirdodge_Success:
  li  r3,1
  b EnterAirdodge_Exit
EnterAirdodge_Failed:
  li  r3,0
EnterAirdodge_Exit:
  restore
  blr

#******************************#
#endregion

#******************************#

#region Airdodge_FunctionPointers
Airdodge_FunctionPointers:
blrl
#Enter State Functions
.long 0x00000000  #Unk
.long 0x00000000  #Unk
.long 0x802534ec  #ReleaseNextStateFactory Function (called first when entering the state. is a standard function it seems)
.long 0xCCCCCCCC  #EneterState Function (sets initial values and spawns things)
#Per Frame Functions
.long 0x00000000  #Unk
.long 0x00000000  #Unk
.long 0xCCCCCCCC  #ReleaseCurrentState (called when leaving state)
.long 0xCCCCCCCC  #procAnim (Animation)
.long 0xCCCCCCCC  #ProcMove (Physics)
.long 0x8050c040  #ProcConstraint (Unk)
.long 0xCCCCCCCC  #ProcFixPos (Collision)
.long 0x80053c10  #procObjCollReact (onGrab)
.long 0x8050c04c  #procEnd (miscellaneous per frame function)
#endregion

#******************************#

#region EnterState_Airdodge
EnterState_Airdodge:
blrl
.set Player,31
.set Buffer,30
.set CreateStateBase,0x8050c024
.set EnterState,0x801a3c50
.set SetXlu,0x80502898
.set State_Airdodge,0x1BC

backup

EnterState_Airdodge_RemoveJumpReleaseFlag:
  li  r5,0
  stb r5,0xC(r3)    #Remove some other flag

#Get pointers
  lwz r4,0x8(r3)
  lwz Player,0x4(r3)

#Create state base?
  mr  r3,Player
  branchl r12,CreateStateBase

#Store pointer to per-frame think functions
  bl  Airdodge_FunctionPointers
  mflr r3
  addi r3,r3,0x10
  stw r3,0x0(Player)

#Init fall flag variable
  li  r3,0
  stw r3,0x8(Player)
#Init timer variable
  li  r3,0
  stw r3,0xC(Player)

#Cannot turn
  GetModel r4
  li  r3,0x1
  stb r3,0x2E61(r4)

#Zero out initial velocity values
  bl Airdodge_Floats
  mflr r4
  lfs f1,0x0(r4)  #X
  lfs f2,0x0(r4)  #Y
#Give momentum based on directions held
#Left = 1, Right = 2, Down = 4, Up = 8
  GetHeldInputs r3
EnterState_Airdodge_CheckLeft:
#Check For Left
  rlwinm. r0,r3,0,31,31
  beq EnterState_Airdodge_CheckRight
#Negative X Velocity
  lfs f1,0x4(r4)
  fneg f1,f1
EnterState_Airdodge_CheckRight:
#Check For Right
  rlwinm. r0,r3,0,30,30
  beq EnterState_Airdodge_CheckDown
#Positive X Velocity
  lfs f1,0x4(r4)
EnterState_Airdodge_CheckDown:
#Check For Down
  rlwinm. r0,r3,0,29,29
  beq EnterState_Airdodge_CheckUp
#Negative Y Velocity
  lfs f2,0x4(r4)
  fneg f2,f2
EnterState_Airdodge_CheckUp:
#Check For Up
  rlwinm. r0,r3,0,28,28
  beq EnterState_Airdodge_MomentumEnd
#Positive Y Velocity
  lfs f2,0x4(r4)
EnterState_Airdodge_MomentumEnd:
#Store velocity, refer to 801a31e4 if this is wrong
  GetMove r3
  stfs f1,0x4(r3)
  stfs f2,0x8(r3)

EnterState_Airdodge_GiveInvincibility:
#Give invincibility
  GetObjColl r3
  branchl r12,SetXlu

EnterState_Airdodge_EnterState:
#Enter State
  lwz Buffer,0x4(Player)      #Get "Zero Buffer Address"
  lwz r3,176(Buffer)          #Get "model"
  addi r3,r3,548              #Get some offset
  li  r4,7 #State_Airdodge       #First new kirby state, use 0x7 for non-custom anim
  branchl r12,EnterState

EnterState_Airdodge_Exit:
mr  r3,Player
restore
blr

Airdodge_Floats:
blrl
  .float 0        #0
  .float 0.25     #Velocity given
  .float 0.9      #per frame velocity multplier

#endregion

#******************************#

#region ReleaseCurrentState_Airdodge
ReleaseCurrentState_Airdodge:
blrl

#Remove airdodge fall flag
  li  r0,0
  stw r0,0x8(r3)
  stw r0,0xC(r3)

blr

#endregion

#******************************#

#region ProcAnim_Airdodge
ProcAnim_Airdodge:
blrl
.set Buffer,31
.set Player,30
.set IsAllEnd,0x80500e64
.set ChangeStateWaitOrFall,0x8050d37c

backup

  mr  Player,r3

#Get Buffer
  lwz Buffer,0x4(r3)

#Increment frames in animation
  lwz r3,0xC(Player)
  addi  r3,r3,1
  stw r3,0xC(Player)
#Check if animation has ended
  GetModel r3
  branchl r12,IsAllEnd
  cmpwi r3,0x0
  beq ProcAnim_Airdodge_Exit
#Enter Fall
  mr  r3,Buffer
  branchl r12,ChangeStateWaitOrFall

ProcAnim_Airdodge_Exit:
restore
blr

#endregion

#******************************#

#region ProcMove_Airdodge
ProcMove_Airdodge:
blrl
.set Buffer,31
.set Player,30
.set MoveDefault,0x8050d518 #0x8050d564
.set UpdateLocation,0x801a33cc
.set UnsetXlu,0x805028fc

backup

#Backup player
  mr Player,r3
#Get Buffer
  lwz Buffer,0x4(Player)
/*
#Check for mint flag
  GetModel r3
  addi r3,r3,640
  li  r4,0
  branchl r12,0x803536e0
  cmpwi r3,0x0
  beq ProcMove_Airdodge_NoFlag
#Store flag to start falling
  li  r3,1
  stw r3,0x8(Player)
ProcMove_Airdodge_NoFlag:
  lwz r3,0x8(Player)
  cmpwi r3,0x0
  beq ProcMove_Airdodge_MultiplyVelocity
*/
#Check if its been 30 frames
  lwz r3,0xC(Player)
  cmpwi r3,AirdodgeFallFrame
  blt ProcMove_Airdodge_MultiplyVelocity
ProcMove_Airdodge_Fall:
#Set Vulnerable
  GetObjColl r3
  branchl r12,UnsetXlu
#Process movement
  mr  r3,Buffer
  branchl r12,MoveDefault
  b ProcMove_Airdodge_Exit
ProcMove_Airdodge_MultiplyVelocity:
#Multiply Velocity
  bl  Airdodge_Floats
  mflr  r3
  GetMove r4
  lfs f1,0x8(r3)      #Get per frame velocity multiplier
  lfs f2,0x4(r4)
  fmuls f2,f1,f2
  stfs f2,0x4(r4)     #mult X
  lfs f2,0x8(r4)
  fmuls f2,f1,f2
  stfs f2,0x8(r4)     #mult Y
#Move Position
  GetMove r3
  branchl r12,UpdateLocation

ProcMove_Airdodge_Exit:
restore
blr
#endregion

#******************************#

#region ProcFixPos_Airdodge
ProcFixPos_Airdodge:
blrl
.set Buffer,31
.set State,30
.set ClearInvincibility,0x804f0bbc
backup

#Get Buffer
  lwz Buffer,0x4(r3)
#Check ground state
  GetMapColl r3
  lbz r3,0x48(r3)
  cmpwi r3,0x0
  beq ProcFixPos_Airdodge_Exit

#Set Vulnerable
  GetObjColl r3
  branchl r12,UnsetXlu

#Enter Landing
#Check for pending AS change
  GetState State        #remember to check this macro
  mr r3,State
  branchl r12,onSetNextStateFactory
#Unknown
  addi r3,State,0x10
  addi r4,State,144
  branchl r12,UtilStateFactory
#Store pointer to state change functions
  load r3,0x807c01a8      #Landing function pointers
  stw r3,0x10(State)
  stw Buffer,0x18(State)
#Add to AS change queue
  addi r3,State,0x10
  stw r3,0xC(State)

ProcFixPos_Airdodge_Exit:
restore
blr

#endregion

#******************************#
