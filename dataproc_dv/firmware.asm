
firmware.elf:     file format elf32-littleriscv


Disassembly of section .text:

00100000 <_start>:
  100000:	00020137          	lui	sp,0x20
  100004:	00000517          	auipc	a0,0x0
  100008:	21c50513          	addi	a0,a0,540 # 100220 <_etext>
  10000c:	00000593          	li	a1,0
  100010:	00000613          	li	a2,0
  100014:	00c5dc63          	bge	a1,a2,10002c <_start+0x2c>
  100018:	00052283          	lw	t0,0(a0)
  10001c:	0055a023          	sw	t0,0(a1)
  100020:	00450513          	addi	a0,a0,4
  100024:	00458593          	addi	a1,a1,4
  100028:	fec5c8e3          	blt	a1,a2,100018 <_start+0x18>
  10002c:	00000513          	li	a0,0
  100030:	00000593          	li	a1,0
  100034:	00b55863          	bge	a0,a1,100044 <_start+0x44>
  100038:	00052023          	sw	zero,0(a0)
  10003c:	00450513          	addi	a0,a0,4
  100040:	feb54ce3          	blt	a0,a1,100038 <_start+0x38>
  100044:	12c000ef          	jal	ra,100170 <main>
  100048:	0000006f          	j	100048 <_start+0x48>

0010004c <putchar>:
  10004c:	fe010113          	addi	sp,sp,-32 # 1ffe0 <_ebss+0x1ffe0>
  100050:	00112e23          	sw	ra,28(sp)
  100054:	00812c23          	sw	s0,24(sp)
  100058:	02010413          	addi	s0,sp,32
  10005c:	00050793          	mv	a5,a0
  100060:	fef407a3          	sb	a5,-17(s0)
  100064:	fef44703          	lbu	a4,-17(s0)
  100068:	00a00793          	li	a5,10
  10006c:	00f71663          	bne	a4,a5,100078 <putchar+0x2c>
  100070:	00d00513          	li	a0,13
  100074:	fd9ff0ef          	jal	ra,10004c <putchar>
  100078:	020007b7          	lui	a5,0x2000
  10007c:	00878793          	addi	a5,a5,8 # 2000008 <_etext+0x1effde8>
  100080:	fef44703          	lbu	a4,-17(s0)
  100084:	00e7a023          	sw	a4,0(a5)
  100088:	00000013          	nop
  10008c:	01c12083          	lw	ra,28(sp)
  100090:	01812403          	lw	s0,24(sp)
  100094:	02010113          	addi	sp,sp,32
  100098:	00008067          	ret

0010009c <print_dec>:
  10009c:	fd010113          	addi	sp,sp,-48
  1000a0:	02112623          	sw	ra,44(sp)
  1000a4:	02812423          	sw	s0,40(sp)
  1000a8:	03010413          	addi	s0,sp,48
  1000ac:	fca42e23          	sw	a0,-36(s0)
  1000b0:	fe042623          	sw	zero,-20(s0)
  1000b4:	fdc42783          	lw	a5,-36(s0)
  1000b8:	00079863          	bnez	a5,1000c8 <print_dec+0x2c>
  1000bc:	03000513          	li	a0,48
  1000c0:	f8dff0ef          	jal	ra,10004c <putchar>
  1000c4:	09c0006f          	j	100160 <print_dec+0xc4>
  1000c8:	fdc42783          	lw	a5,-36(s0)
  1000cc:	0407de63          	bgez	a5,100128 <print_dec+0x8c>
  1000d0:	02d00513          	li	a0,45
  1000d4:	f79ff0ef          	jal	ra,10004c <putchar>
  1000d8:	fdc42783          	lw	a5,-36(s0)
  1000dc:	40f007b3          	neg	a5,a5
  1000e0:	fcf42e23          	sw	a5,-36(s0)
  1000e4:	0440006f          	j	100128 <print_dec+0x8c>
  1000e8:	fdc42703          	lw	a4,-36(s0)
  1000ec:	00a00793          	li	a5,10
  1000f0:	02f767b3          	rem	a5,a4,a5
  1000f4:	0ff7f713          	andi	a4,a5,255
  1000f8:	fec42783          	lw	a5,-20(s0)
  1000fc:	00178693          	addi	a3,a5,1
  100100:	fed42623          	sw	a3,-20(s0)
  100104:	03070713          	addi	a4,a4,48
  100108:	0ff77713          	andi	a4,a4,255
  10010c:	ff040693          	addi	a3,s0,-16
  100110:	00f687b3          	add	a5,a3,a5
  100114:	fee78823          	sb	a4,-16(a5)
  100118:	fdc42703          	lw	a4,-36(s0)
  10011c:	00a00793          	li	a5,10
  100120:	02f747b3          	div	a5,a4,a5
  100124:	fcf42e23          	sw	a5,-36(s0)
  100128:	fdc42783          	lw	a5,-36(s0)
  10012c:	fa079ee3          	bnez	a5,1000e8 <print_dec+0x4c>
  100130:	01c0006f          	j	10014c <print_dec+0xb0>
  100134:	fec42783          	lw	a5,-20(s0)
  100138:	ff040713          	addi	a4,s0,-16
  10013c:	00f707b3          	add	a5,a4,a5
  100140:	ff07c783          	lbu	a5,-16(a5)
  100144:	00078513          	mv	a0,a5
  100148:	f05ff0ef          	jal	ra,10004c <putchar>
  10014c:	fec42783          	lw	a5,-20(s0)
  100150:	fff78793          	addi	a5,a5,-1
  100154:	fef42623          	sw	a5,-20(s0)
  100158:	fec42783          	lw	a5,-20(s0)
  10015c:	fc07dce3          	bgez	a5,100134 <print_dec+0x98>
  100160:	02c12083          	lw	ra,44(sp)
  100164:	02812403          	lw	s0,40(sp)
  100168:	03010113          	addi	sp,sp,48
  10016c:	00008067          	ret

00100170 <main>:
  100170:	fe010113          	addi	sp,sp,-32
  100174:	00112e23          	sw	ra,28(sp)
  100178:	00812c23          	sw	s0,24(sp)
  10017c:	02010413          	addi	s0,sp,32
  100180:	020007b7          	lui	a5,0x2000
  100184:	00478793          	addi	a5,a5,4 # 2000004 <_etext+0x1effde4>
  100188:	01300713          	li	a4,19
  10018c:	00e7a023          	sw	a4,0(a5)
  100190:	040007b7          	lui	a5,0x4000
  100194:	0007a023          	sw	zero,0(a5) # 4000000 <_etext+0x3effde0>
  100198:	030007b7          	lui	a5,0x3000
  10019c:	0007a023          	sw	zero,0(a5) # 3000000 <_etext+0x2effde0>
  1001a0:	05200513          	li	a0,82
  1001a4:	ea9ff0ef          	jal	ra,10004c <putchar>
  1001a8:	06500513          	li	a0,101
  1001ac:	ea1ff0ef          	jal	ra,10004c <putchar>
  1001b0:	06100513          	li	a0,97
  1001b4:	e99ff0ef          	jal	ra,10004c <putchar>
  1001b8:	06400513          	li	a0,100
  1001bc:	e91ff0ef          	jal	ra,10004c <putchar>
  1001c0:	07900513          	li	a0,121
  1001c4:	e89ff0ef          	jal	ra,10004c <putchar>
  1001c8:	00a00513          	li	a0,10
  1001cc:	e81ff0ef          	jal	ra,10004c <putchar>
  1001d0:	00000013          	nop
  1001d4:	040007b7          	lui	a5,0x4000
  1001d8:	04478793          	addi	a5,a5,68 # 4000044 <_etext+0x3effe24>
  1001dc:	0007a783          	lw	a5,0(a5)
  1001e0:	0017f793          	andi	a5,a5,1
  1001e4:	fe0788e3          	beqz	a5,1001d4 <main+0x64>
  1001e8:	040007b7          	lui	a5,0x4000
  1001ec:	04078793          	addi	a5,a5,64 # 4000040 <_etext+0x3effe20>
  1001f0:	0007a783          	lw	a5,0(a5)
  1001f4:	fef42623          	sw	a5,-20(s0)
  1001f8:	fec42503          	lw	a0,-20(s0)
  1001fc:	ea1ff0ef          	jal	ra,10009c <print_dec>
  100200:	02000513          	li	a0,32
  100204:	e49ff0ef          	jal	ra,10004c <putchar>
  100208:	030007b7          	lui	a5,0x3000
  10020c:	0007a703          	lw	a4,0(a5) # 3000000 <_etext+0x2effde0>
  100210:	030007b7          	lui	a5,0x3000
  100214:	00174713          	xori	a4,a4,1
  100218:	00e7a023          	sw	a4,0(a5) # 3000000 <_etext+0x2effde0>
  10021c:	fb5ff06f          	j	1001d0 <main+0x60>
