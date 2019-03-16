#To be inserted at 804ea164
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

.macro loadf regf,reg,address
lis \reg, \address @h
ori \reg, \reg, \address @l
stw \reg,-0x4(sp)
lfs \regf,-0x4(sp)
.endm

.macro backup
addi sp,sp,-0x4
mflr r0
stw r0,0(sp)
.endm

.macro restore
lwz r0,0(sp)
mtlr r0
addi sp,sp,0x4
.endm

.macro intToFloat reg,reg2
xoris    \reg,\reg,0x8000
lis    r18,0x4330
lfd    f16,-0x7470(rtoc)    # load magic number
stw    r18,0(r2)
stw    \reg,4(r2)
lfd    \reg2,0(r2)
fsubs    \reg2,\reg2,f16
.endm

.macro getPlayerBlock reg1,reg2
lwz \reg1,0x2c(\reg2)
.endm

.macro getCharID reg
lbz \reg,0x7(player)
.endm

.macro getCostumeID reg
lbz \reg,0x619(player)
.endm

.macro getAS reg
lwz \reg,0x10(player)
.endm

.macro getASFrame reg
lwz \reg,0x894(player)
.endm

.macro getFacing reg
lwz \reg,0x2c(player)
.endm

.macro setFacing reg
stw \reg,0x2c(player)
.endm

.macro invertFacing reg
lfs \reg,0x2c(player)
fneg \reg,\reg
stfs \reg,0x2c(player)
.endm

.macro fsetGroundVelocityX reg
stfs \reg,0xec(player)
.endm

.macro fsetAirVelocityX reg
stfs \reg,0x80(player)
.endm

.macro fsetAirVelocityY reg
stfs \reg,0x84(player)
.endm

.macro fgetGroundVelocityX reg
lfs \reg,0xec(player)
.endm

.macro fgetAirVelocityX reg
lfs \reg,0x80(player)
.endm

.macro fgetAirVelocityY reg
lfs \reg,0x84(player)
.endm

.macro setGroundVelocityX reg
stw \reg,0xec(player)
.endm

.macro setAirVelocityX reg
stw \reg,0x80(player)
.endm

.macro setAirVelocityY reg
stw \reg,0x84(player)
.endm

.macro getGroundVelocityX reg
lwz \reg,0xec(player)
.endm

.macro getAirVelocityX reg
lwz \reg,0x80(player)
.endm

.macro getAirVelocityY reg
lwz \reg,0x84(player)
.endm

.macro getGroundAirState reg
lwz \reg,0xe0(player)
.endm

.macro getPlayerDatAddress reg
lwz \reg,0x108(player)
.endm

.macro getStaticBlock reg, reg2
lbz \reg,0xc(player)			#get player slot (0-3)
li \reg2,0xe90			#static player block length
mullw \reg2,\reg,\reg2			#multiply block length by player number
lis \reg,0x8045			#load in static player block base address
ori \reg,\reg,0x3080			#load in static player block base address
add \reg,\reg,\reg2			#add length to base address to get current player's block
#playerblock address in \reg
.endm

.macro getDpad reg
lbz \reg,0x66b(player)
.endm

.macro getPlayerSlot reg
lbz \reg,0xC(player)
.endm

.macro get reg offset
lwz \reg,\offset(player)
.endm

.macro checkInstantButtons input
addi	r3, block, 220
lwz	r3, 0x0004 (r3)
li r4, \input
bl r11,0x804ee788
.endm

.macro checkButtons input
addi	r3, block, 220
lwz	r3, 0x0004 (r3)
li r4, \input
bl r11,0x801a9e7c
.endm

.macro getVelocityBA reg
addi	\reg, block, 164
lwz	\reg, 0x0004 (\reg)
.endm

.macro getFacingBA reg
lwz	\reg, 0x0004 (block)
addi	\reg, \reg, 172
lwz	\reg, 0x0004 (\reg)
.endm

.set ActionStateChange,0x800693ac
.set HSD_Randi,0x80380580
.set HSD_Randf,0x80380528
.set Wait,0x8008a348
.set Fall,0x800cc730

.set block,30
.set player,31

stwu	sp, -0x0060 (sp)
stw	r12, 0x0064 (sp)

main:
	mr r18,r3

	checkJC:
	bl getASID
	##get JCTable address in r15##
	mflr r14
	bl JCTable
	mflr r15
	mtlr r14
	bl checkTable
	cmpwi r3,0x0
	beq checkAC
	bl checkForJC

	checkAC:
	bl getASID
	##get ACTable address in r15##
	mflr r14
	bl ACTable
	mflr r15
	mtlr r14
	bl checkTableAC
	cmpwi r3,0x0
	beq checkAJC
	bl checkForAC

	checkAJC:
	bl getASID
	##get AJCTable address in r15##
	mflr r14
	bl AJCTable
	mflr r15
	mtlr r14
	bl checkTable
	cmpwi r3,0x0
	beq continue
	bl checkForAJC
	





getASID:
lwz	r3, 0x0004 (r18)
addi	r3, r3, 172			#model__Q43scn4step4hero4HeroFv
lwz	r3, 0x0004 (r3)			#model__Q43scn4step4hero4HeroFv
addi	r3, r3, 548
lwz r3,0x54(r3)
blr

checkTable:
#get 0x0000FFFF in r17
li r17,0
ori r17,r17,0xFFFF

#Current AS ID in r3, table in r15, value from table in r16,0xFFFF in r17
Loop:
lhz r16,0x0(r15)
cmpw r16,r17
beq exitLoop
cmpw r16,r3
addi r15,r15,0x2
bne Loop

li r3,0x1
blr

#if you're here, move is either not jc-able or no jc input was detected
exitLoop:
li r3,0x0
blr


checkTableAC:
#get 0x0000FFFF in r17
li r17,0
ori r17,r17,0xFFFF

#Current AS ID in r3, table in r15, value from table in r16,0xFFFF in r17
LoopAC:
lhz r16,0x0(r15)
cmpw r16,r17
beq exitLoopAC
cmpw r16,r3
addi r15,r15,0x4
bne LoopAC

li r3,0x1
blr

#if you're here, move is either not jc-able or no jc input was detected
exitLoopAC:
li r3,0x0
blr

checkForJC:
lwz	r3, 0x0004 (r18)
branchl r11,0x805224bc
cmpwi r3,0x1
beq return
b checkAC

checkForAC:
##Table Offset in r15
##Action State ID in r16
lwz r3,0x318(block)
lwz r3,0x8(r3)
cmpwi r16,0x18
bgt specialASTimer
cmpwi r16,0x2
beq  specialASTimer
b commonASTimer

commonASTimer:
lwz r3,0x8(r3)
b continueAC

specialASTimer:
lwz r3,0xC(r3)

continueAC:
lbz r14,-0x2(r15) #get starting frame in r14
cmpw r3,r14		#check if current frame is equal to or after the start iasa frame
bge AC_AfterStartingFrame
b continue #exit

AC_AfterStartingFrame:
lbz r14,-0x1(r15) #get ending frame in r14
cmpw r3,r14		#check if current frame is equal to or before the end iasa frame
ble ACInterruptAllow
b continue #exit

ACInterruptAllow:
lwz	r3, 0x0004 (r18)
addi	r3, r3, 284
lwz	r3, 0x0004 (r3)
branchl r11,0x804d11a4
cmpwi r3,0x1
beq return
b checkAJC

checkForAJC:
lwz	r3, 0x0004 (r18)
branchl r11,0x80520a28
cmpwi r3,0x1
beq return
b continue


#############################################################
JCTable:
blrl
.long 0x0105000B #parasol dash and slide
.long 0x00B10079 #fire and sword dash
.long 0x008C00BC #cut and spike dash
.long 0x009E0126 #leaf dash and tornado nuetral
.long 0x015B0161 #ninja dash and down
.long 0x01510174 #bird dash and fighter dash (no hold)
.long 0x01320142 #hammer dash and ice down dash
.long 0x014000F1 #ice dash and water down
.long 0x00F1FFFF #water down
############################################################

############################################################
ACTable:
blrl
## XXXX YY ZZ
## XXXX = AS ID
## YY = starting frame
## ZZ = ending frame
.long 0x000B000A #slide
.long 0x00EE00FF #water dash attack
.long 0x00EF00FF #water dash attack
.long 0xFFFFFFFF #end
#############################################################

############################################################
AJCTable:
blrl
.long 0x00EE00EF #water dash start and dash mid
.long 0xFFFFFFFF #
#############################################################

continue:
lwz r12, 0x0064 (sp)
addi sp,sp,96
mtctr r12

mr r3,r18
bctrl
b returnAndSkip

return:
addi sp,sp,96

returnAndSkip:


