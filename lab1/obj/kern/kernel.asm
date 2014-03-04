
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 60 1b 10 f0 	movl   $0xf0101b60,(%esp)
f0100055:	e8 38 0a 00 00       	call   f0100a92 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 c9 07 00 00       	call   f0100850 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 7c 1b 10 f0 	movl   $0xf0101b7c,(%esp)
f0100092:	e8 fb 09 00 00       	call   f0100a92 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 8c 15 00 00       	call   f0101651 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 92 04 00 00       	call   f010055c <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 97 1b 10 f0 	movl   $0xf0101b97,(%esp)
f01000d9:	e8 b4 09 00 00       	call   f0100a92 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 1a 08 00 00       	call   f0100910 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 b2 1b 10 f0 	movl   $0xf0101bb2,(%esp)
f010012c:	e8 61 09 00 00       	call   f0100a92 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 22 09 00 00       	call   f0100a5f <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 ee 1b 10 f0 	movl   $0xf0101bee,(%esp)
f0100144:	e8 49 09 00 00       	call   f0100a92 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 bb 07 00 00       	call   f0100910 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 ca 1b 10 f0 	movl   $0xf0101bca,(%esp)
f0100176:	e8 17 09 00 00       	call   f0100a92 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 d5 08 00 00       	call   f0100a5f <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 ee 1b 10 f0 	movl   $0xf0101bee,(%esp)
f0100191:	e8 fc 08 00 00       	call   f0100a92 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	00 00                	add    %al,(%eax)
	...

f01001a0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a8:	ec                   	in     (%dx),%al
f01001a9:	ec                   	in     (%dx),%al
f01001aa:	ec                   	in     (%dx),%al
f01001ab:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001ac:	5d                   	pop    %ebp
f01001ad:	c3                   	ret    

f01001ae <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001ae:	55                   	push   %ebp
f01001af:	89 e5                	mov    %esp,%ebp
f01001b1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b6:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b7:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001bc:	a8 01                	test   $0x1,%al
f01001be:	74 06                	je     f01001c6 <serial_proc_data+0x18>
f01001c0:	b2 f8                	mov    $0xf8,%dl
f01001c2:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001c3:	0f b6 c8             	movzbl %al,%ecx
}
f01001c6:	89 c8                	mov    %ecx,%eax
f01001c8:	5d                   	pop    %ebp
f01001c9:	c3                   	ret    

f01001ca <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ca:	55                   	push   %ebp
f01001cb:	89 e5                	mov    %esp,%ebp
f01001cd:	53                   	push   %ebx
f01001ce:	83 ec 04             	sub    $0x4,%esp
f01001d1:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001d3:	eb 25                	jmp    f01001fa <cons_intr+0x30>
		if (c == 0)
f01001d5:	85 c0                	test   %eax,%eax
f01001d7:	74 21                	je     f01001fa <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f01001d9:	8b 15 24 25 11 f0    	mov    0xf0112524,%edx
f01001df:	88 82 20 23 11 f0    	mov    %al,-0xfeedce0(%edx)
f01001e5:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01001e8:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01001ed:	ba 00 00 00 00       	mov    $0x0,%edx
f01001f2:	0f 44 c2             	cmove  %edx,%eax
f01001f5:	a3 24 25 11 f0       	mov    %eax,0xf0112524
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001fa:	ff d3                	call   *%ebx
f01001fc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001ff:	75 d4                	jne    f01001d5 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100201:	83 c4 04             	add    $0x4,%esp
f0100204:	5b                   	pop    %ebx
f0100205:	5d                   	pop    %ebp
f0100206:	c3                   	ret    

f0100207 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100207:	55                   	push   %ebp
f0100208:	89 e5                	mov    %esp,%ebp
f010020a:	57                   	push   %edi
f010020b:	56                   	push   %esi
f010020c:	53                   	push   %ebx
f010020d:	83 ec 2c             	sub    $0x2c,%esp
f0100210:	89 c7                	mov    %eax,%edi
f0100212:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100217:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100218:	a8 20                	test   $0x20,%al
f010021a:	75 1b                	jne    f0100237 <cons_putc+0x30>
f010021c:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100221:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f0100226:	e8 75 ff ff ff       	call   f01001a0 <delay>
f010022b:	89 f2                	mov    %esi,%edx
f010022d:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010022e:	a8 20                	test   $0x20,%al
f0100230:	75 05                	jne    f0100237 <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100232:	83 eb 01             	sub    $0x1,%ebx
f0100235:	75 ef                	jne    f0100226 <cons_putc+0x1f>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100237:	89 fa                	mov    %edi,%edx
f0100239:	89 f8                	mov    %edi,%eax
f010023b:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010023e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100243:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100244:	b2 79                	mov    $0x79,%dl
f0100246:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100247:	84 c0                	test   %al,%al
f0100249:	78 1b                	js     f0100266 <cons_putc+0x5f>
f010024b:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100250:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f0100255:	e8 46 ff ff ff       	call   f01001a0 <delay>
f010025a:	89 f2                	mov    %esi,%edx
f010025c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010025d:	84 c0                	test   %al,%al
f010025f:	78 05                	js     f0100266 <cons_putc+0x5f>
f0100261:	83 eb 01             	sub    $0x1,%ebx
f0100264:	75 ef                	jne    f0100255 <cons_putc+0x4e>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100266:	ba 78 03 00 00       	mov    $0x378,%edx
f010026b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010026f:	ee                   	out    %al,(%dx)
f0100270:	b2 7a                	mov    $0x7a,%dl
f0100272:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100277:	ee                   	out    %al,(%dx)
f0100278:	b8 08 00 00 00       	mov    $0x8,%eax
f010027d:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010027e:	89 fa                	mov    %edi,%edx
f0100280:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100286:	89 f8                	mov    %edi,%eax
f0100288:	80 cc 07             	or     $0x7,%ah
f010028b:	85 d2                	test   %edx,%edx
f010028d:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100290:	89 f8                	mov    %edi,%eax
f0100292:	25 ff 00 00 00       	and    $0xff,%eax
f0100297:	83 f8 09             	cmp    $0x9,%eax
f010029a:	74 7c                	je     f0100318 <cons_putc+0x111>
f010029c:	83 f8 09             	cmp    $0x9,%eax
f010029f:	7f 0b                	jg     f01002ac <cons_putc+0xa5>
f01002a1:	83 f8 08             	cmp    $0x8,%eax
f01002a4:	0f 85 a2 00 00 00    	jne    f010034c <cons_putc+0x145>
f01002aa:	eb 16                	jmp    f01002c2 <cons_putc+0xbb>
f01002ac:	83 f8 0a             	cmp    $0xa,%eax
f01002af:	90                   	nop
f01002b0:	74 40                	je     f01002f2 <cons_putc+0xeb>
f01002b2:	83 f8 0d             	cmp    $0xd,%eax
f01002b5:	0f 85 91 00 00 00    	jne    f010034c <cons_putc+0x145>
f01002bb:	90                   	nop
f01002bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01002c0:	eb 38                	jmp    f01002fa <cons_putc+0xf3>
	case '\b':
		if (crt_pos > 0) {
f01002c2:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f01002c9:	66 85 c0             	test   %ax,%ax
f01002cc:	0f 84 e4 00 00 00    	je     f01003b6 <cons_putc+0x1af>
			crt_pos--;
f01002d2:	83 e8 01             	sub    $0x1,%eax
f01002d5:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002db:	0f b7 c0             	movzwl %ax,%eax
f01002de:	66 81 e7 00 ff       	and    $0xff00,%di
f01002e3:	83 cf 20             	or     $0x20,%edi
f01002e6:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f01002ec:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002f0:	eb 77                	jmp    f0100369 <cons_putc+0x162>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002f2:	66 83 05 34 25 11 f0 	addw   $0x50,0xf0112534
f01002f9:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002fa:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f0100301:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100307:	c1 e8 16             	shr    $0x16,%eax
f010030a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010030d:	c1 e0 04             	shl    $0x4,%eax
f0100310:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
f0100316:	eb 51                	jmp    f0100369 <cons_putc+0x162>
		break;
	case '\t':
		cons_putc(' ');
f0100318:	b8 20 00 00 00       	mov    $0x20,%eax
f010031d:	e8 e5 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100322:	b8 20 00 00 00       	mov    $0x20,%eax
f0100327:	e8 db fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f010032c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100331:	e8 d1 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100336:	b8 20 00 00 00       	mov    $0x20,%eax
f010033b:	e8 c7 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100340:	b8 20 00 00 00       	mov    $0x20,%eax
f0100345:	e8 bd fe ff ff       	call   f0100207 <cons_putc>
f010034a:	eb 1d                	jmp    f0100369 <cons_putc+0x162>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010034c:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f0100353:	0f b7 c8             	movzwl %ax,%ecx
f0100356:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f010035c:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100360:	83 c0 01             	add    $0x1,%eax
f0100363:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100369:	66 81 3d 34 25 11 f0 	cmpw   $0x7cf,0xf0112534
f0100370:	cf 07 
f0100372:	76 42                	jbe    f01003b6 <cons_putc+0x1af>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100374:	a1 30 25 11 f0       	mov    0xf0112530,%eax
f0100379:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100380:	00 
f0100381:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100387:	89 54 24 04          	mov    %edx,0x4(%esp)
f010038b:	89 04 24             	mov    %eax,(%esp)
f010038e:	e8 19 13 00 00       	call   f01016ac <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100393:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100399:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010039e:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01003a4:	83 c0 01             	add    $0x1,%eax
f01003a7:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01003ac:	75 f0                	jne    f010039e <cons_putc+0x197>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01003ae:	66 83 2d 34 25 11 f0 	subw   $0x50,0xf0112534
f01003b5:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01003b6:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01003bc:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003c1:	89 ca                	mov    %ecx,%edx
f01003c3:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003c4:	0f b7 35 34 25 11 f0 	movzwl 0xf0112534,%esi
f01003cb:	8d 59 01             	lea    0x1(%ecx),%ebx
f01003ce:	89 f0                	mov    %esi,%eax
f01003d0:	66 c1 e8 08          	shr    $0x8,%ax
f01003d4:	89 da                	mov    %ebx,%edx
f01003d6:	ee                   	out    %al,(%dx)
f01003d7:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003dc:	89 ca                	mov    %ecx,%edx
f01003de:	ee                   	out    %al,(%dx)
f01003df:	89 f0                	mov    %esi,%eax
f01003e1:	89 da                	mov    %ebx,%edx
f01003e3:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003e4:	83 c4 2c             	add    $0x2c,%esp
f01003e7:	5b                   	pop    %ebx
f01003e8:	5e                   	pop    %esi
f01003e9:	5f                   	pop    %edi
f01003ea:	5d                   	pop    %ebp
f01003eb:	c3                   	ret    

f01003ec <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003ec:	55                   	push   %ebp
f01003ed:	89 e5                	mov    %esp,%ebp
f01003ef:	53                   	push   %ebx
f01003f0:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003f3:	ba 64 00 00 00       	mov    $0x64,%edx
f01003f8:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003f9:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01003fe:	a8 01                	test   $0x1,%al
f0100400:	0f 84 de 00 00 00    	je     f01004e4 <kbd_proc_data+0xf8>
f0100406:	b2 60                	mov    $0x60,%dl
f0100408:	ec                   	in     (%dx),%al
f0100409:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010040b:	3c e0                	cmp    $0xe0,%al
f010040d:	75 11                	jne    f0100420 <kbd_proc_data+0x34>
		// E0 escape character
		shift |= E0ESC;
f010040f:	83 0d 28 25 11 f0 40 	orl    $0x40,0xf0112528
		return 0;
f0100416:	bb 00 00 00 00       	mov    $0x0,%ebx
f010041b:	e9 c4 00 00 00       	jmp    f01004e4 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f0100420:	84 c0                	test   %al,%al
f0100422:	79 37                	jns    f010045b <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100424:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f010042a:	89 cb                	mov    %ecx,%ebx
f010042c:	83 e3 40             	and    $0x40,%ebx
f010042f:	83 e0 7f             	and    $0x7f,%eax
f0100432:	85 db                	test   %ebx,%ebx
f0100434:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100437:	0f b6 d2             	movzbl %dl,%edx
f010043a:	0f b6 82 20 1c 10 f0 	movzbl -0xfefe3e0(%edx),%eax
f0100441:	83 c8 40             	or     $0x40,%eax
f0100444:	0f b6 c0             	movzbl %al,%eax
f0100447:	f7 d0                	not    %eax
f0100449:	21 c1                	and    %eax,%ecx
f010044b:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
		return 0;
f0100451:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100456:	e9 89 00 00 00       	jmp    f01004e4 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f010045b:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f0100461:	f6 c1 40             	test   $0x40,%cl
f0100464:	74 0e                	je     f0100474 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100466:	89 c2                	mov    %eax,%edx
f0100468:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010046b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010046e:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
	}

	shift |= shiftcode[data];
f0100474:	0f b6 d2             	movzbl %dl,%edx
f0100477:	0f b6 82 20 1c 10 f0 	movzbl -0xfefe3e0(%edx),%eax
f010047e:	0b 05 28 25 11 f0    	or     0xf0112528,%eax
	shift ^= togglecode[data];
f0100484:	0f b6 8a 20 1d 10 f0 	movzbl -0xfefe2e0(%edx),%ecx
f010048b:	31 c8                	xor    %ecx,%eax
f010048d:	a3 28 25 11 f0       	mov    %eax,0xf0112528

	c = charcode[shift & (CTL | SHIFT)][data];
f0100492:	89 c1                	mov    %eax,%ecx
f0100494:	83 e1 03             	and    $0x3,%ecx
f0100497:	8b 0c 8d 20 1e 10 f0 	mov    -0xfefe1e0(,%ecx,4),%ecx
f010049e:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f01004a2:	a8 08                	test   $0x8,%al
f01004a4:	74 19                	je     f01004bf <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f01004a6:	8d 53 9f             	lea    -0x61(%ebx),%edx
f01004a9:	83 fa 19             	cmp    $0x19,%edx
f01004ac:	77 05                	ja     f01004b3 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f01004ae:	83 eb 20             	sub    $0x20,%ebx
f01004b1:	eb 0c                	jmp    f01004bf <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f01004b3:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f01004b6:	8d 53 20             	lea    0x20(%ebx),%edx
f01004b9:	83 f9 19             	cmp    $0x19,%ecx
f01004bc:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01004bf:	f7 d0                	not    %eax
f01004c1:	a8 06                	test   $0x6,%al
f01004c3:	75 1f                	jne    f01004e4 <kbd_proc_data+0xf8>
f01004c5:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004cb:	75 17                	jne    f01004e4 <kbd_proc_data+0xf8>
		cprintf("Rebooting!\n");
f01004cd:	c7 04 24 e4 1b 10 f0 	movl   $0xf0101be4,(%esp)
f01004d4:	e8 b9 05 00 00       	call   f0100a92 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004d9:	ba 92 00 00 00       	mov    $0x92,%edx
f01004de:	b8 03 00 00 00       	mov    $0x3,%eax
f01004e3:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004e4:	89 d8                	mov    %ebx,%eax
f01004e6:	83 c4 14             	add    $0x14,%esp
f01004e9:	5b                   	pop    %ebx
f01004ea:	5d                   	pop    %ebp
f01004eb:	c3                   	ret    

f01004ec <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004ec:	55                   	push   %ebp
f01004ed:	89 e5                	mov    %esp,%ebp
f01004ef:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f01004f2:	80 3d 00 23 11 f0 00 	cmpb   $0x0,0xf0112300
f01004f9:	74 0a                	je     f0100505 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f01004fb:	b8 ae 01 10 f0       	mov    $0xf01001ae,%eax
f0100500:	e8 c5 fc ff ff       	call   f01001ca <cons_intr>
}
f0100505:	c9                   	leave  
f0100506:	c3                   	ret    

f0100507 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100507:	55                   	push   %ebp
f0100508:	89 e5                	mov    %esp,%ebp
f010050a:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010050d:	b8 ec 03 10 f0       	mov    $0xf01003ec,%eax
f0100512:	e8 b3 fc ff ff       	call   f01001ca <cons_intr>
}
f0100517:	c9                   	leave  
f0100518:	c3                   	ret    

f0100519 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100519:	55                   	push   %ebp
f010051a:	89 e5                	mov    %esp,%ebp
f010051c:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010051f:	e8 c8 ff ff ff       	call   f01004ec <serial_intr>
	kbd_intr();
f0100524:	e8 de ff ff ff       	call   f0100507 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100529:	8b 15 20 25 11 f0    	mov    0xf0112520,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f010052f:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100534:	3b 15 24 25 11 f0    	cmp    0xf0112524,%edx
f010053a:	74 1e                	je     f010055a <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f010053c:	0f b6 82 20 23 11 f0 	movzbl -0xfeedce0(%edx),%eax
f0100543:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f0100546:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010054c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100551:	0f 44 d1             	cmove  %ecx,%edx
f0100554:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
		return c;
	}
	return 0;
}
f010055a:	c9                   	leave  
f010055b:	c3                   	ret    

f010055c <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010055c:	55                   	push   %ebp
f010055d:	89 e5                	mov    %esp,%ebp
f010055f:	57                   	push   %edi
f0100560:	56                   	push   %esi
f0100561:	53                   	push   %ebx
f0100562:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100565:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010056c:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100573:	5a a5 
	if (*cp != 0xA55A) {
f0100575:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010057c:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100580:	74 11                	je     f0100593 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100582:	c7 05 2c 25 11 f0 b4 	movl   $0x3b4,0xf011252c
f0100589:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010058c:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100591:	eb 16                	jmp    f01005a9 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100593:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010059a:	c7 05 2c 25 11 f0 d4 	movl   $0x3d4,0xf011252c
f01005a1:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005a4:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005a9:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01005af:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005b4:	89 ca                	mov    %ecx,%edx
f01005b6:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005b7:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ba:	89 da                	mov    %ebx,%edx
f01005bc:	ec                   	in     (%dx),%al
f01005bd:	0f b6 f8             	movzbl %al,%edi
f01005c0:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c3:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005c8:	89 ca                	mov    %ecx,%edx
f01005ca:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cb:	89 da                	mov    %ebx,%edx
f01005cd:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005ce:	89 35 30 25 11 f0    	mov    %esi,0xf0112530

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005d4:	0f b6 d8             	movzbl %al,%ebx
f01005d7:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005d9:	66 89 3d 34 25 11 f0 	mov    %di,0xf0112534
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005e0:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005e5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ea:	89 da                	mov    %ebx,%edx
f01005ec:	ee                   	out    %al,(%dx)
f01005ed:	b2 fb                	mov    $0xfb,%dl
f01005ef:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005f4:	ee                   	out    %al,(%dx)
f01005f5:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f01005fa:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005ff:	89 ca                	mov    %ecx,%edx
f0100601:	ee                   	out    %al,(%dx)
f0100602:	b2 f9                	mov    $0xf9,%dl
f0100604:	b8 00 00 00 00       	mov    $0x0,%eax
f0100609:	ee                   	out    %al,(%dx)
f010060a:	b2 fb                	mov    $0xfb,%dl
f010060c:	b8 03 00 00 00       	mov    $0x3,%eax
f0100611:	ee                   	out    %al,(%dx)
f0100612:	b2 fc                	mov    $0xfc,%dl
f0100614:	b8 00 00 00 00       	mov    $0x0,%eax
f0100619:	ee                   	out    %al,(%dx)
f010061a:	b2 f9                	mov    $0xf9,%dl
f010061c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100621:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100622:	b2 fd                	mov    $0xfd,%dl
f0100624:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100625:	3c ff                	cmp    $0xff,%al
f0100627:	0f 95 c0             	setne  %al
f010062a:	89 c6                	mov    %eax,%esi
f010062c:	a2 00 23 11 f0       	mov    %al,0xf0112300
f0100631:	89 da                	mov    %ebx,%edx
f0100633:	ec                   	in     (%dx),%al
f0100634:	89 ca                	mov    %ecx,%edx
f0100636:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100637:	89 f0                	mov    %esi,%eax
f0100639:	84 c0                	test   %al,%al
f010063b:	75 0c                	jne    f0100649 <cons_init+0xed>
		cprintf("Serial port does not exist!\n");
f010063d:	c7 04 24 f0 1b 10 f0 	movl   $0xf0101bf0,(%esp)
f0100644:	e8 49 04 00 00       	call   f0100a92 <cprintf>
}
f0100649:	83 c4 1c             	add    $0x1c,%esp
f010064c:	5b                   	pop    %ebx
f010064d:	5e                   	pop    %esi
f010064e:	5f                   	pop    %edi
f010064f:	5d                   	pop    %ebp
f0100650:	c3                   	ret    

f0100651 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100651:	55                   	push   %ebp
f0100652:	89 e5                	mov    %esp,%ebp
f0100654:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100657:	8b 45 08             	mov    0x8(%ebp),%eax
f010065a:	e8 a8 fb ff ff       	call   f0100207 <cons_putc>
}
f010065f:	c9                   	leave  
f0100660:	c3                   	ret    

f0100661 <getchar>:

int
getchar(void)
{
f0100661:	55                   	push   %ebp
f0100662:	89 e5                	mov    %esp,%ebp
f0100664:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100667:	e8 ad fe ff ff       	call   f0100519 <cons_getc>
f010066c:	85 c0                	test   %eax,%eax
f010066e:	74 f7                	je     f0100667 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100670:	c9                   	leave  
f0100671:	c3                   	ret    

f0100672 <iscons>:

int
iscons(int fdnum)
{
f0100672:	55                   	push   %ebp
f0100673:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100675:	b8 01 00 00 00       	mov    $0x1,%eax
f010067a:	5d                   	pop    %ebp
f010067b:	c3                   	ret    
f010067c:	00 00                	add    %al,(%eax)
	...

f0100680 <mon_setcolor>:
	return 0;
}

int
mon_setcolor(int argc, char **argv, struct Trapframe *tf)
{
f0100680:	55                   	push   %ebp
f0100681:	89 e5                	mov    %esp,%ebp
f0100683:	57                   	push   %edi
f0100684:	56                   	push   %esi
f0100685:	53                   	push   %ebx
f0100686:	83 ec 1c             	sub    $0x1c,%esp
f0100689:	8b 75 0c             	mov    0xc(%ebp),%esi
 	if(argc != 3)
f010068c:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
f0100690:	74 4a                	je     f01006dc <mon_setcolor+0x5c>
	{
		cprintf("     Choose the color you like.\n");
f0100692:	c7 04 24 30 1e 10 f0 	movl   $0xf0101e30,(%esp)
f0100699:	e8 f4 03 00 00       	call   f0100a92 <cprintf>
		cprintf("     The color board:\n");
f010069e:	c7 04 24 e0 20 10 f0 	movl   $0xf01020e0,(%esp)
f01006a5:	e8 e8 03 00 00       	call   f0100a92 <cprintf>
		cprintf("     Background Color|Foreground Color\n");
f01006aa:	c7 04 24 54 1e 10 f0 	movl   $0xf0101e54,(%esp)
f01006b1:	e8 dc 03 00 00       	call   f0100a92 <cprintf>
		cprintf("      I | R | G | B | | I | R | G | B\n"); 
f01006b6:	c7 04 24 7c 1e 10 f0 	movl   $0xf0101e7c,(%esp)
f01006bd:	e8 d0 03 00 00       	call   f0100a92 <cprintf>
	 	cprintf("     Your input should be: setcolor [8-bit binary number] [a string you want to output]\n");
f01006c2:	c7 04 24 a4 1e 10 f0 	movl   $0xf0101ea4,(%esp)
f01006c9:	e8 c4 03 00 00       	call   f0100a92 <cprintf>
		cprintf("     Example:setcolor 10000001 Example\n");
f01006ce:	c7 04 24 00 1f 10 f0 	movl   $0xf0101f00,(%esp)
f01006d5:	e8 b8 03 00 00       	call   f0100a92 <cprintf>
		return 0;
f01006da:	eb 5e                	jmp    f010073a <mon_setcolor+0xba>
	}
	int tempcolor = 0;
	int i=0;
	for(i = 0; i < 8; i++)
	{
		tempcolor = tempcolor * 2 + argv[1][i] - '0';
f01006dc:	8b 4e 04             	mov    0x4(%esi),%ecx
f01006df:	b8 00 00 00 00       	mov    $0x0,%eax
f01006e4:	bf 00 00 00 00       	mov    $0x0,%edi
f01006e9:	0f be 14 01          	movsbl (%ecx,%eax,1),%edx
f01006ed:	8d 7c 7a d0          	lea    -0x30(%edx,%edi,2),%edi
		cprintf("     Example:setcolor 10000001 Example\n");
		return 0;
	}
	int tempcolor = 0;
	int i=0;
	for(i = 0; i < 8; i++)
f01006f1:	83 c0 01             	add    $0x1,%eax
f01006f4:	83 f8 08             	cmp    $0x8,%eax
f01006f7:	75 f0                	jne    f01006e9 <mon_setcolor+0x69>
	{
		tempcolor = tempcolor * 2 + argv[1][i] - '0';
	}
	tempcolor = tempcolor << 8;
f01006f9:	c1 e7 08             	shl    $0x8,%edi
	int c;
	for(i = 0; argv[2][i] != '\0'; i++)
f01006fc:	8b 46 08             	mov    0x8(%esi),%eax
f01006ff:	0f b6 00             	movzbl (%eax),%eax
f0100702:	84 c0                	test   %al,%al
f0100704:	74 28                	je     f010072e <mon_setcolor+0xae>
f0100706:	bb 00 00 00 00       	mov    $0x0,%ebx
	{
		c = (int)argv[2][i];
f010070b:	0f be c0             	movsbl %al,%eax
		c = c | tempcolor;
f010070e:	09 f8                	or     %edi,%eax
		cprintf("%c",c);
f0100710:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100714:	c7 04 24 f7 20 10 f0 	movl   $0xf01020f7,(%esp)
f010071b:	e8 72 03 00 00       	call   f0100a92 <cprintf>
	{
		tempcolor = tempcolor * 2 + argv[1][i] - '0';
	}
	tempcolor = tempcolor << 8;
	int c;
	for(i = 0; argv[2][i] != '\0'; i++)
f0100720:	83 c3 01             	add    $0x1,%ebx
f0100723:	8b 46 08             	mov    0x8(%esi),%eax
f0100726:	0f b6 04 18          	movzbl (%eax,%ebx,1),%eax
f010072a:	84 c0                	test   %al,%al
f010072c:	75 dd                	jne    f010070b <mon_setcolor+0x8b>
	{
		c = (int)argv[2][i];
		c = c | tempcolor;
		cprintf("%c",c);
	}
	cprintf("\n");
f010072e:	c7 04 24 ee 1b 10 f0 	movl   $0xf0101bee,(%esp)
f0100735:	e8 58 03 00 00       	call   f0100a92 <cprintf>
	return 0;
}
f010073a:	b8 00 00 00 00       	mov    $0x0,%eax
f010073f:	83 c4 1c             	add    $0x1c,%esp
f0100742:	5b                   	pop    %ebx
f0100743:	5e                   	pop    %esi
f0100744:	5f                   	pop    %edi
f0100745:	5d                   	pop    %ebp
f0100746:	c3                   	ret    

f0100747 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100747:	55                   	push   %ebp
f0100748:	89 e5                	mov    %esp,%ebp
f010074a:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010074d:	c7 04 24 fa 20 10 f0 	movl   $0xf01020fa,(%esp)
f0100754:	e8 39 03 00 00       	call   f0100a92 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100759:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100760:	00 
f0100761:	c7 04 24 28 1f 10 f0 	movl   $0xf0101f28,(%esp)
f0100768:	e8 25 03 00 00       	call   f0100a92 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010076d:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100774:	00 
f0100775:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f010077c:	f0 
f010077d:	c7 04 24 50 1f 10 f0 	movl   $0xf0101f50,(%esp)
f0100784:	e8 09 03 00 00       	call   f0100a92 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100789:	c7 44 24 08 45 1b 10 	movl   $0x101b45,0x8(%esp)
f0100790:	00 
f0100791:	c7 44 24 04 45 1b 10 	movl   $0xf0101b45,0x4(%esp)
f0100798:	f0 
f0100799:	c7 04 24 74 1f 10 f0 	movl   $0xf0101f74,(%esp)
f01007a0:	e8 ed 02 00 00       	call   f0100a92 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007a5:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f01007ac:	00 
f01007ad:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f01007b4:	f0 
f01007b5:	c7 04 24 98 1f 10 f0 	movl   $0xf0101f98,(%esp)
f01007bc:	e8 d1 02 00 00       	call   f0100a92 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007c1:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f01007c8:	00 
f01007c9:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f01007d0:	f0 
f01007d1:	c7 04 24 bc 1f 10 f0 	movl   $0xf0101fbc,(%esp)
f01007d8:	e8 b5 02 00 00       	call   f0100a92 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01007dd:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f01007e2:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01007e7:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007ec:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01007f2:	85 c0                	test   %eax,%eax
f01007f4:	0f 48 c2             	cmovs  %edx,%eax
f01007f7:	c1 f8 0a             	sar    $0xa,%eax
f01007fa:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007fe:	c7 04 24 e0 1f 10 f0 	movl   $0xf0101fe0,(%esp)
f0100805:	e8 88 02 00 00       	call   f0100a92 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010080a:	b8 00 00 00 00       	mov    $0x0,%eax
f010080f:	c9                   	leave  
f0100810:	c3                   	ret    

f0100811 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100811:	55                   	push   %ebp
f0100812:	89 e5                	mov    %esp,%ebp
f0100814:	53                   	push   %ebx
f0100815:	83 ec 14             	sub    $0x14,%esp
f0100818:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010081d:	8b 83 04 22 10 f0    	mov    -0xfefddfc(%ebx),%eax
f0100823:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100827:	8b 83 00 22 10 f0    	mov    -0xfefde00(%ebx),%eax
f010082d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100831:	c7 04 24 13 21 10 f0 	movl   $0xf0102113,(%esp)
f0100838:	e8 55 02 00 00       	call   f0100a92 <cprintf>
f010083d:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100840:	83 fb 30             	cmp    $0x30,%ebx
f0100843:	75 d8                	jne    f010081d <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f0100845:	b8 00 00 00 00       	mov    $0x0,%eax
f010084a:	83 c4 14             	add    $0x14,%esp
f010084d:	5b                   	pop    %ebx
f010084e:	5d                   	pop    %ebp
f010084f:	c3                   	ret    

f0100850 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100850:	55                   	push   %ebp
f0100851:	89 e5                	mov    %esp,%ebp
f0100853:	56                   	push   %esi
f0100854:	53                   	push   %ebx
f0100855:	83 ec 40             	sub    $0x40,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100858:	89 eb                	mov    %ebp,%ebx
	// Your code here.
	uint32_t* ebp = (uint32_t*) read_ebp();
f010085a:	89 de                	mov    %ebx,%esi
	cprintf("Stack backtrace:\n");
f010085c:	c7 04 24 1c 21 10 f0 	movl   $0xf010211c,(%esp)
f0100863:	e8 2a 02 00 00       	call   f0100a92 <cprintf>
	while (ebp != 0) {
f0100868:	85 db                	test   %ebx,%ebx
f010086a:	0f 84 94 00 00 00    	je     f0100904 <mon_backtrace+0xb4>
	    cprintf("  ebp %08x  eip %08x", ebp, *(ebp+1));
	    cprintf("  args %08x %08x %08x %08x %08x\n", *(ebp+2), *(ebp+3), *(ebp+4), *(ebp+5), *(ebp+6));
	    struct Eipdebuginfo info;
	    debuginfo_eip(*(ebp+1), &info);
f0100870:	8d 5d e0             	lea    -0x20(%ebp),%ebx
{
	// Your code here.
	uint32_t* ebp = (uint32_t*) read_ebp();
	cprintf("Stack backtrace:\n");
	while (ebp != 0) {
	    cprintf("  ebp %08x  eip %08x", ebp, *(ebp+1));
f0100873:	8b 46 04             	mov    0x4(%esi),%eax
f0100876:	89 44 24 08          	mov    %eax,0x8(%esp)
f010087a:	89 74 24 04          	mov    %esi,0x4(%esp)
f010087e:	c7 04 24 2e 21 10 f0 	movl   $0xf010212e,(%esp)
f0100885:	e8 08 02 00 00       	call   f0100a92 <cprintf>
	    cprintf("  args %08x %08x %08x %08x %08x\n", *(ebp+2), *(ebp+3), *(ebp+4), *(ebp+5), *(ebp+6));
f010088a:	8b 46 18             	mov    0x18(%esi),%eax
f010088d:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100891:	8b 46 14             	mov    0x14(%esi),%eax
f0100894:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100898:	8b 46 10             	mov    0x10(%esi),%eax
f010089b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010089f:	8b 46 0c             	mov    0xc(%esi),%eax
f01008a2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008a6:	8b 46 08             	mov    0x8(%esi),%eax
f01008a9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008ad:	c7 04 24 0c 20 10 f0 	movl   $0xf010200c,(%esp)
f01008b4:	e8 d9 01 00 00       	call   f0100a92 <cprintf>
	    struct Eipdebuginfo info;
	    debuginfo_eip(*(ebp+1), &info);
f01008b9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01008bd:	8b 46 04             	mov    0x4(%esi),%eax
f01008c0:	89 04 24             	mov    %eax,(%esp)
f01008c3:	e8 c4 02 00 00       	call   f0100b8c <debuginfo_eip>
	    cprintf("         %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, 							 info.eip_fn_name, *(ebp + 1) - info.eip_fn_addr);
f01008c8:	8b 46 04             	mov    0x4(%esi),%eax
f01008cb:	2b 45 f0             	sub    -0x10(%ebp),%eax
f01008ce:	89 44 24 14          	mov    %eax,0x14(%esp)
f01008d2:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01008d5:	89 44 24 10          	mov    %eax,0x10(%esp)
f01008d9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01008dc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01008e0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01008e3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008e7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01008ea:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008ee:	c7 04 24 43 21 10 f0 	movl   $0xf0102143,(%esp)
f01008f5:	e8 98 01 00 00       	call   f0100a92 <cprintf>
   	    ebp = (uint32_t*) *ebp;
f01008fa:	8b 36                	mov    (%esi),%esi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	uint32_t* ebp = (uint32_t*) read_ebp();
	cprintf("Stack backtrace:\n");
	while (ebp != 0) {
f01008fc:	85 f6                	test   %esi,%esi
f01008fe:	0f 85 6f ff ff ff    	jne    f0100873 <mon_backtrace+0x23>
	    debuginfo_eip(*(ebp+1), &info);
	    cprintf("         %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, 							 info.eip_fn_name, *(ebp + 1) - info.eip_fn_addr);
   	    ebp = (uint32_t*) *ebp;
	}
	return 0;
}
f0100904:	b8 00 00 00 00       	mov    $0x0,%eax
f0100909:	83 c4 40             	add    $0x40,%esp
f010090c:	5b                   	pop    %ebx
f010090d:	5e                   	pop    %esi
f010090e:	5d                   	pop    %ebp
f010090f:	c3                   	ret    

f0100910 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100910:	55                   	push   %ebp
f0100911:	89 e5                	mov    %esp,%ebp
f0100913:	57                   	push   %edi
f0100914:	56                   	push   %esi
f0100915:	53                   	push   %ebx
f0100916:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100919:	c7 04 24 30 20 10 f0 	movl   $0xf0102030,(%esp)
f0100920:	e8 6d 01 00 00       	call   f0100a92 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100925:	c7 04 24 54 20 10 f0 	movl   $0xf0102054,(%esp)
f010092c:	e8 61 01 00 00       	call   f0100a92 <cprintf>
	//unsigned int i = 0x00646c72;
        //cprintf("H%x Wo%s", 57616, &i);
	//cprintf("x=%d y=%d", 3);

	while (1) {
		buf = readline("K> ");
f0100931:	c7 04 24 5c 21 10 f0 	movl   $0xf010215c,(%esp)
f0100938:	e8 63 0a 00 00       	call   f01013a0 <readline>
f010093d:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010093f:	85 c0                	test   %eax,%eax
f0100941:	74 ee                	je     f0100931 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100943:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010094a:	be 00 00 00 00       	mov    $0x0,%esi
f010094f:	eb 06                	jmp    f0100957 <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100951:	c6 03 00             	movb   $0x0,(%ebx)
f0100954:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100957:	0f b6 03             	movzbl (%ebx),%eax
f010095a:	84 c0                	test   %al,%al
f010095c:	74 6d                	je     f01009cb <monitor+0xbb>
f010095e:	0f be c0             	movsbl %al,%eax
f0100961:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100965:	c7 04 24 60 21 10 f0 	movl   $0xf0102160,(%esp)
f010096c:	e8 85 0c 00 00       	call   f01015f6 <strchr>
f0100971:	85 c0                	test   %eax,%eax
f0100973:	75 dc                	jne    f0100951 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100975:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100978:	74 51                	je     f01009cb <monitor+0xbb>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010097a:	83 fe 0f             	cmp    $0xf,%esi
f010097d:	8d 76 00             	lea    0x0(%esi),%esi
f0100980:	75 16                	jne    f0100998 <monitor+0x88>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100982:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100989:	00 
f010098a:	c7 04 24 65 21 10 f0 	movl   $0xf0102165,(%esp)
f0100991:	e8 fc 00 00 00       	call   f0100a92 <cprintf>
f0100996:	eb 99                	jmp    f0100931 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100998:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010099c:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f010099f:	0f b6 03             	movzbl (%ebx),%eax
f01009a2:	84 c0                	test   %al,%al
f01009a4:	75 0c                	jne    f01009b2 <monitor+0xa2>
f01009a6:	eb af                	jmp    f0100957 <monitor+0x47>
			buf++;
f01009a8:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01009ab:	0f b6 03             	movzbl (%ebx),%eax
f01009ae:	84 c0                	test   %al,%al
f01009b0:	74 a5                	je     f0100957 <monitor+0x47>
f01009b2:	0f be c0             	movsbl %al,%eax
f01009b5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009b9:	c7 04 24 60 21 10 f0 	movl   $0xf0102160,(%esp)
f01009c0:	e8 31 0c 00 00       	call   f01015f6 <strchr>
f01009c5:	85 c0                	test   %eax,%eax
f01009c7:	74 df                	je     f01009a8 <monitor+0x98>
f01009c9:	eb 8c                	jmp    f0100957 <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f01009cb:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009d2:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009d3:	85 f6                	test   %esi,%esi
f01009d5:	0f 84 56 ff ff ff    	je     f0100931 <monitor+0x21>
f01009db:	bb 00 22 10 f0       	mov    $0xf0102200,%ebx
f01009e0:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009e5:	8b 03                	mov    (%ebx),%eax
f01009e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009eb:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01009ee:	89 04 24             	mov    %eax,(%esp)
f01009f1:	e8 85 0b 00 00       	call   f010157b <strcmp>
f01009f6:	85 c0                	test   %eax,%eax
f01009f8:	75 24                	jne    f0100a1e <monitor+0x10e>
			return commands[i].func(argc, argv, tf);
f01009fa:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01009fd:	8b 55 08             	mov    0x8(%ebp),%edx
f0100a00:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100a04:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a07:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100a0b:	89 34 24             	mov    %esi,(%esp)
f0100a0e:	ff 14 85 08 22 10 f0 	call   *-0xfefddf8(,%eax,4)
	//cprintf("x=%d y=%d", 3);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a15:	85 c0                	test   %eax,%eax
f0100a17:	78 28                	js     f0100a41 <monitor+0x131>
f0100a19:	e9 13 ff ff ff       	jmp    f0100931 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100a1e:	83 c7 01             	add    $0x1,%edi
f0100a21:	83 c3 0c             	add    $0xc,%ebx
f0100a24:	83 ff 04             	cmp    $0x4,%edi
f0100a27:	75 bc                	jne    f01009e5 <monitor+0xd5>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a29:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a2c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a30:	c7 04 24 82 21 10 f0 	movl   $0xf0102182,(%esp)
f0100a37:	e8 56 00 00 00       	call   f0100a92 <cprintf>
f0100a3c:	e9 f0 fe ff ff       	jmp    f0100931 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a41:	83 c4 5c             	add    $0x5c,%esp
f0100a44:	5b                   	pop    %ebx
f0100a45:	5e                   	pop    %esi
f0100a46:	5f                   	pop    %edi
f0100a47:	5d                   	pop    %ebp
f0100a48:	c3                   	ret    
f0100a49:	00 00                	add    %al,(%eax)
	...

f0100a4c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a4c:	55                   	push   %ebp
f0100a4d:	89 e5                	mov    %esp,%ebp
f0100a4f:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100a52:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a55:	89 04 24             	mov    %eax,(%esp)
f0100a58:	e8 f4 fb ff ff       	call   f0100651 <cputchar>
	*cnt++;
}
f0100a5d:	c9                   	leave  
f0100a5e:	c3                   	ret    

f0100a5f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100a5f:	55                   	push   %ebp
f0100a60:	89 e5                	mov    %esp,%ebp
f0100a62:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100a65:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a6c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100a6f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a73:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a76:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100a7a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a7d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a81:	c7 04 24 4c 0a 10 f0 	movl   $0xf0100a4c,(%esp)
f0100a88:	e8 f7 04 00 00       	call   f0100f84 <vprintfmt>
	return cnt;
}
f0100a8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a90:	c9                   	leave  
f0100a91:	c3                   	ret    

f0100a92 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a92:	55                   	push   %ebp
f0100a93:	89 e5                	mov    %esp,%ebp
f0100a95:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a98:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a9b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a9f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100aa2:	89 04 24             	mov    %eax,(%esp)
f0100aa5:	e8 b5 ff ff ff       	call   f0100a5f <vcprintf>
	va_end(ap);

	return cnt;
}
f0100aaa:	c9                   	leave  
f0100aab:	c3                   	ret    

f0100aac <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100aac:	55                   	push   %ebp
f0100aad:	89 e5                	mov    %esp,%ebp
f0100aaf:	57                   	push   %edi
f0100ab0:	56                   	push   %esi
f0100ab1:	53                   	push   %ebx
f0100ab2:	83 ec 10             	sub    $0x10,%esp
f0100ab5:	89 c3                	mov    %eax,%ebx
f0100ab7:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100aba:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100abd:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100ac0:	8b 0a                	mov    (%edx),%ecx
f0100ac2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ac5:	8b 00                	mov    (%eax),%eax
f0100ac7:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100aca:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100ad1:	eb 77                	jmp    f0100b4a <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0100ad3:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100ad6:	01 c8                	add    %ecx,%eax
f0100ad8:	bf 02 00 00 00       	mov    $0x2,%edi
f0100add:	99                   	cltd   
f0100ade:	f7 ff                	idiv   %edi
f0100ae0:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100ae2:	eb 01                	jmp    f0100ae5 <stab_binsearch+0x39>
			m--;
f0100ae4:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100ae5:	39 ca                	cmp    %ecx,%edx
f0100ae7:	7c 1d                	jl     f0100b06 <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100ae9:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100aec:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0100af1:	39 f7                	cmp    %esi,%edi
f0100af3:	75 ef                	jne    f0100ae4 <stab_binsearch+0x38>
f0100af5:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100af8:	6b fa 0c             	imul   $0xc,%edx,%edi
f0100afb:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0100aff:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100b02:	73 18                	jae    f0100b1c <stab_binsearch+0x70>
f0100b04:	eb 05                	jmp    f0100b0b <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100b06:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0100b09:	eb 3f                	jmp    f0100b4a <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100b0b:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100b0e:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0100b10:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b13:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100b1a:	eb 2e                	jmp    f0100b4a <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100b1c:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100b1f:	76 15                	jbe    f0100b36 <stab_binsearch+0x8a>
			*region_right = m - 1;
f0100b21:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100b24:	4f                   	dec    %edi
f0100b25:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0100b28:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b2b:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b2d:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100b34:	eb 14                	jmp    f0100b4a <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100b36:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100b39:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100b3c:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0100b3e:	ff 45 0c             	incl   0xc(%ebp)
f0100b41:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b43:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100b4a:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0100b4d:	7e 84                	jle    f0100ad3 <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100b4f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100b53:	75 0d                	jne    f0100b62 <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0100b55:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b58:	8b 02                	mov    (%edx),%eax
f0100b5a:	48                   	dec    %eax
f0100b5b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b5e:	89 01                	mov    %eax,(%ecx)
f0100b60:	eb 22                	jmp    f0100b84 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b62:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b65:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b67:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b6a:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b6c:	eb 01                	jmp    f0100b6f <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100b6e:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b6f:	39 c1                	cmp    %eax,%ecx
f0100b71:	7d 0c                	jge    f0100b7f <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100b73:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100b76:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0100b7b:	39 f2                	cmp    %esi,%edx
f0100b7d:	75 ef                	jne    f0100b6e <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100b7f:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b82:	89 02                	mov    %eax,(%edx)
	}
}
f0100b84:	83 c4 10             	add    $0x10,%esp
f0100b87:	5b                   	pop    %ebx
f0100b88:	5e                   	pop    %esi
f0100b89:	5f                   	pop    %edi
f0100b8a:	5d                   	pop    %ebp
f0100b8b:	c3                   	ret    

f0100b8c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b8c:	55                   	push   %ebp
f0100b8d:	89 e5                	mov    %esp,%ebp
f0100b8f:	83 ec 58             	sub    $0x58,%esp
f0100b92:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100b95:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100b98:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100b9b:	8b 75 08             	mov    0x8(%ebp),%esi
f0100b9e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100ba1:	c7 03 30 22 10 f0    	movl   $0xf0102230,(%ebx)
	info->eip_line = 0;
f0100ba7:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100bae:	c7 43 08 30 22 10 f0 	movl   $0xf0102230,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100bb5:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100bbc:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100bbf:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100bc6:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100bcc:	76 12                	jbe    f0100be0 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bce:	b8 db 7b 10 f0       	mov    $0xf0107bdb,%eax
f0100bd3:	3d 55 62 10 f0       	cmp    $0xf0106255,%eax
f0100bd8:	0f 86 f1 01 00 00    	jbe    f0100dcf <debuginfo_eip+0x243>
f0100bde:	eb 1c                	jmp    f0100bfc <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100be0:	c7 44 24 08 3a 22 10 	movl   $0xf010223a,0x8(%esp)
f0100be7:	f0 
f0100be8:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100bef:	00 
f0100bf0:	c7 04 24 47 22 10 f0 	movl   $0xf0102247,(%esp)
f0100bf7:	e8 fc f4 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100bfc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100c01:	80 3d da 7b 10 f0 00 	cmpb   $0x0,0xf0107bda
f0100c08:	0f 85 cd 01 00 00    	jne    f0100ddb <debuginfo_eip+0x24f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100c0e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100c15:	b8 54 62 10 f0       	mov    $0xf0106254,%eax
f0100c1a:	2d 68 24 10 f0       	sub    $0xf0102468,%eax
f0100c1f:	c1 f8 02             	sar    $0x2,%eax
f0100c22:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100c28:	83 e8 01             	sub    $0x1,%eax
f0100c2b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100c2e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c32:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100c39:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100c3c:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100c3f:	b8 68 24 10 f0       	mov    $0xf0102468,%eax
f0100c44:	e8 63 fe ff ff       	call   f0100aac <stab_binsearch>
	if (lfile == 0)
f0100c49:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0100c4c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100c51:	85 d2                	test   %edx,%edx
f0100c53:	0f 84 82 01 00 00    	je     f0100ddb <debuginfo_eip+0x24f>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c59:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100c5c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c5f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c62:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c66:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100c6d:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c70:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c73:	b8 68 24 10 f0       	mov    $0xf0102468,%eax
f0100c78:	e8 2f fe ff ff       	call   f0100aac <stab_binsearch>

	if (lfun <= rfun) {
f0100c7d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100c80:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100c83:	39 d0                	cmp    %edx,%eax
f0100c85:	7f 3d                	jg     f0100cc4 <debuginfo_eip+0x138>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c87:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100c8a:	8d b9 68 24 10 f0    	lea    -0xfefdb98(%ecx),%edi
f0100c90:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0100c93:	8b 89 68 24 10 f0    	mov    -0xfefdb98(%ecx),%ecx
f0100c99:	bf db 7b 10 f0       	mov    $0xf0107bdb,%edi
f0100c9e:	81 ef 55 62 10 f0    	sub    $0xf0106255,%edi
f0100ca4:	39 f9                	cmp    %edi,%ecx
f0100ca6:	73 09                	jae    f0100cb1 <debuginfo_eip+0x125>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100ca8:	81 c1 55 62 10 f0    	add    $0xf0106255,%ecx
f0100cae:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100cb1:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100cb4:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100cb7:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100cba:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100cbc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100cbf:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100cc2:	eb 0f                	jmp    f0100cd3 <debuginfo_eip+0x147>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100cc4:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100cc7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cca:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100ccd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cd0:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100cd3:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100cda:	00 
f0100cdb:	8b 43 08             	mov    0x8(%ebx),%eax
f0100cde:	89 04 24             	mov    %eax,(%esp)
f0100ce1:	e8 44 09 00 00       	call   f010162a <strfind>
f0100ce6:	2b 43 08             	sub    0x8(%ebx),%eax
f0100ce9:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100cec:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100cf0:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100cf7:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100cfa:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100cfd:	b8 68 24 10 f0       	mov    $0xf0102468,%eax
f0100d02:	e8 a5 fd ff ff       	call   f0100aac <stab_binsearch>
	if (lline <= rline)
f0100d07:	8b 55 d4             	mov    -0x2c(%ebp),%edx
		info->eip_line = stabs[lline].n_desc;
	else
		return -1;
f0100d0a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if (lline <= rline)
f0100d0f:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100d12:	0f 8f c3 00 00 00    	jg     f0100ddb <debuginfo_eip+0x24f>
		info->eip_line = stabs[lline].n_desc;
f0100d18:	6b d2 0c             	imul   $0xc,%edx,%edx
f0100d1b:	0f b7 82 6e 24 10 f0 	movzwl -0xfefdb92(%edx),%eax
f0100d22:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d25:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d28:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100d2b:	39 c8                	cmp    %ecx,%eax
f0100d2d:	7c 5f                	jl     f0100d8e <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f0100d2f:	89 c2                	mov    %eax,%edx
f0100d31:	6b f0 0c             	imul   $0xc,%eax,%esi
f0100d34:	80 be 6c 24 10 f0 84 	cmpb   $0x84,-0xfefdb94(%esi)
f0100d3b:	75 18                	jne    f0100d55 <debuginfo_eip+0x1c9>
f0100d3d:	eb 30                	jmp    f0100d6f <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100d3f:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d42:	39 c1                	cmp    %eax,%ecx
f0100d44:	7f 48                	jg     f0100d8e <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f0100d46:	89 c2                	mov    %eax,%edx
f0100d48:	8d 34 40             	lea    (%eax,%eax,2),%esi
f0100d4b:	80 3c b5 6c 24 10 f0 	cmpb   $0x84,-0xfefdb94(,%esi,4)
f0100d52:	84 
f0100d53:	74 1a                	je     f0100d6f <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100d55:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100d58:	8d 14 95 68 24 10 f0 	lea    -0xfefdb98(,%edx,4),%edx
f0100d5f:	80 7a 04 64          	cmpb   $0x64,0x4(%edx)
f0100d63:	75 da                	jne    f0100d3f <debuginfo_eip+0x1b3>
f0100d65:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100d69:	74 d4                	je     f0100d3f <debuginfo_eip+0x1b3>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100d6b:	39 c1                	cmp    %eax,%ecx
f0100d6d:	7f 1f                	jg     f0100d8e <debuginfo_eip+0x202>
f0100d6f:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100d72:	8b 80 68 24 10 f0    	mov    -0xfefdb98(%eax),%eax
f0100d78:	ba db 7b 10 f0       	mov    $0xf0107bdb,%edx
f0100d7d:	81 ea 55 62 10 f0    	sub    $0xf0106255,%edx
f0100d83:	39 d0                	cmp    %edx,%eax
f0100d85:	73 07                	jae    f0100d8e <debuginfo_eip+0x202>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100d87:	05 55 62 10 f0       	add    $0xf0106255,%eax
f0100d8c:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d8e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100d91:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d94:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d99:	39 ca                	cmp    %ecx,%edx
f0100d9b:	7d 3e                	jge    f0100ddb <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
f0100d9d:	83 c2 01             	add    $0x1,%edx
f0100da0:	39 d1                	cmp    %edx,%ecx
f0100da2:	7e 37                	jle    f0100ddb <debuginfo_eip+0x24f>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100da4:	6b f2 0c             	imul   $0xc,%edx,%esi
f0100da7:	80 be 6c 24 10 f0 a0 	cmpb   $0xa0,-0xfefdb94(%esi)
f0100dae:	75 2b                	jne    f0100ddb <debuginfo_eip+0x24f>
		     lline++)
			info->eip_fn_narg++;
f0100db0:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100db4:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100db7:	39 d1                	cmp    %edx,%ecx
f0100db9:	7e 1b                	jle    f0100dd6 <debuginfo_eip+0x24a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100dbb:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100dbe:	80 3c 85 6c 24 10 f0 	cmpb   $0xa0,-0xfefdb94(,%eax,4)
f0100dc5:	a0 
f0100dc6:	74 e8                	je     f0100db0 <debuginfo_eip+0x224>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100dc8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dcd:	eb 0c                	jmp    f0100ddb <debuginfo_eip+0x24f>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100dcf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100dd4:	eb 05                	jmp    f0100ddb <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100dd6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100ddb:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100dde:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100de1:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100de4:	89 ec                	mov    %ebp,%esp
f0100de6:	5d                   	pop    %ebp
f0100de7:	c3                   	ret    
	...

f0100df0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100df0:	55                   	push   %ebp
f0100df1:	89 e5                	mov    %esp,%ebp
f0100df3:	57                   	push   %edi
f0100df4:	56                   	push   %esi
f0100df5:	53                   	push   %ebx
f0100df6:	83 ec 3c             	sub    $0x3c,%esp
f0100df9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100dfc:	89 d7                	mov    %edx,%edi
f0100dfe:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e01:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100e04:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e07:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e0a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100e0d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100e10:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e15:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100e18:	72 11                	jb     f0100e2b <printnum+0x3b>
f0100e1a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100e1d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100e20:	76 09                	jbe    f0100e2b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e22:	83 eb 01             	sub    $0x1,%ebx
f0100e25:	85 db                	test   %ebx,%ebx
f0100e27:	7f 51                	jg     f0100e7a <printnum+0x8a>
f0100e29:	eb 5e                	jmp    f0100e89 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100e2b:	89 74 24 10          	mov    %esi,0x10(%esp)
f0100e2f:	83 eb 01             	sub    $0x1,%ebx
f0100e32:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100e36:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e39:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e3d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0100e41:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0100e45:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100e4c:	00 
f0100e4d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100e50:	89 04 24             	mov    %eax,(%esp)
f0100e53:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e56:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e5a:	e8 41 0a 00 00       	call   f01018a0 <__udivdi3>
f0100e5f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100e63:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100e67:	89 04 24             	mov    %eax,(%esp)
f0100e6a:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100e6e:	89 fa                	mov    %edi,%edx
f0100e70:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e73:	e8 78 ff ff ff       	call   f0100df0 <printnum>
f0100e78:	eb 0f                	jmp    f0100e89 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e7a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e7e:	89 34 24             	mov    %esi,(%esp)
f0100e81:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e84:	83 eb 01             	sub    $0x1,%ebx
f0100e87:	75 f1                	jne    f0100e7a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e89:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e8d:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100e91:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e94:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e98:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100e9f:	00 
f0100ea0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ea3:	89 04 24             	mov    %eax,(%esp)
f0100ea6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ea9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ead:	e8 1e 0b 00 00       	call   f01019d0 <__umoddi3>
f0100eb2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100eb6:	0f be 80 55 22 10 f0 	movsbl -0xfefddab(%eax),%eax
f0100ebd:	89 04 24             	mov    %eax,(%esp)
f0100ec0:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100ec3:	83 c4 3c             	add    $0x3c,%esp
f0100ec6:	5b                   	pop    %ebx
f0100ec7:	5e                   	pop    %esi
f0100ec8:	5f                   	pop    %edi
f0100ec9:	5d                   	pop    %ebp
f0100eca:	c3                   	ret    

f0100ecb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100ecb:	55                   	push   %ebp
f0100ecc:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100ece:	83 fa 01             	cmp    $0x1,%edx
f0100ed1:	7e 0e                	jle    f0100ee1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100ed3:	8b 10                	mov    (%eax),%edx
f0100ed5:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100ed8:	89 08                	mov    %ecx,(%eax)
f0100eda:	8b 02                	mov    (%edx),%eax
f0100edc:	8b 52 04             	mov    0x4(%edx),%edx
f0100edf:	eb 22                	jmp    f0100f03 <getuint+0x38>
	else if (lflag)
f0100ee1:	85 d2                	test   %edx,%edx
f0100ee3:	74 10                	je     f0100ef5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100ee5:	8b 10                	mov    (%eax),%edx
f0100ee7:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100eea:	89 08                	mov    %ecx,(%eax)
f0100eec:	8b 02                	mov    (%edx),%eax
f0100eee:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ef3:	eb 0e                	jmp    f0100f03 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100ef5:	8b 10                	mov    (%eax),%edx
f0100ef7:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100efa:	89 08                	mov    %ecx,(%eax)
f0100efc:	8b 02                	mov    (%edx),%eax
f0100efe:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100f03:	5d                   	pop    %ebp
f0100f04:	c3                   	ret    

f0100f05 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0100f05:	55                   	push   %ebp
f0100f06:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100f08:	83 fa 01             	cmp    $0x1,%edx
f0100f0b:	7e 0e                	jle    f0100f1b <getint+0x16>
		return va_arg(*ap, long long);
f0100f0d:	8b 10                	mov    (%eax),%edx
f0100f0f:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100f12:	89 08                	mov    %ecx,(%eax)
f0100f14:	8b 02                	mov    (%edx),%eax
f0100f16:	8b 52 04             	mov    0x4(%edx),%edx
f0100f19:	eb 22                	jmp    f0100f3d <getint+0x38>
	else if (lflag)
f0100f1b:	85 d2                	test   %edx,%edx
f0100f1d:	74 10                	je     f0100f2f <getint+0x2a>
		return va_arg(*ap, long);
f0100f1f:	8b 10                	mov    (%eax),%edx
f0100f21:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100f24:	89 08                	mov    %ecx,(%eax)
f0100f26:	8b 02                	mov    (%edx),%eax
f0100f28:	89 c2                	mov    %eax,%edx
f0100f2a:	c1 fa 1f             	sar    $0x1f,%edx
f0100f2d:	eb 0e                	jmp    f0100f3d <getint+0x38>
	else
		return va_arg(*ap, int);
f0100f2f:	8b 10                	mov    (%eax),%edx
f0100f31:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100f34:	89 08                	mov    %ecx,(%eax)
f0100f36:	8b 02                	mov    (%edx),%eax
f0100f38:	89 c2                	mov    %eax,%edx
f0100f3a:	c1 fa 1f             	sar    $0x1f,%edx
}
f0100f3d:	5d                   	pop    %ebp
f0100f3e:	c3                   	ret    

f0100f3f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100f3f:	55                   	push   %ebp
f0100f40:	89 e5                	mov    %esp,%ebp
f0100f42:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100f45:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100f49:	8b 10                	mov    (%eax),%edx
f0100f4b:	3b 50 04             	cmp    0x4(%eax),%edx
f0100f4e:	73 0a                	jae    f0100f5a <sprintputch+0x1b>
		*b->buf++ = ch;
f0100f50:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100f53:	88 0a                	mov    %cl,(%edx)
f0100f55:	83 c2 01             	add    $0x1,%edx
f0100f58:	89 10                	mov    %edx,(%eax)
}
f0100f5a:	5d                   	pop    %ebp
f0100f5b:	c3                   	ret    

f0100f5c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100f5c:	55                   	push   %ebp
f0100f5d:	89 e5                	mov    %esp,%ebp
f0100f5f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100f62:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100f65:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f69:	8b 45 10             	mov    0x10(%ebp),%eax
f0100f6c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100f70:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f73:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f77:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f7a:	89 04 24             	mov    %eax,(%esp)
f0100f7d:	e8 02 00 00 00       	call   f0100f84 <vprintfmt>
	va_end(ap);
}
f0100f82:	c9                   	leave  
f0100f83:	c3                   	ret    

f0100f84 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100f84:	55                   	push   %ebp
f0100f85:	89 e5                	mov    %esp,%ebp
f0100f87:	57                   	push   %edi
f0100f88:	56                   	push   %esi
f0100f89:	53                   	push   %ebx
f0100f8a:	83 ec 4c             	sub    $0x4c,%esp
f0100f8d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f90:	8b 75 10             	mov    0x10(%ebp),%esi
f0100f93:	eb 12                	jmp    f0100fa7 <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100f95:	85 c0                	test   %eax,%eax
f0100f97:	0f 84 77 03 00 00    	je     f0101314 <vprintfmt+0x390>
				return;
			putch(ch, putdat);
f0100f9d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fa1:	89 04 24             	mov    %eax,(%esp)
f0100fa4:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100fa7:	0f b6 06             	movzbl (%esi),%eax
f0100faa:	83 c6 01             	add    $0x1,%esi
f0100fad:	83 f8 25             	cmp    $0x25,%eax
f0100fb0:	75 e3                	jne    f0100f95 <vprintfmt+0x11>
f0100fb2:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100fb6:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100fbd:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0100fc2:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100fc9:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100fce:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100fd1:	eb 2b                	jmp    f0100ffe <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fd3:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100fd6:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100fda:	eb 22                	jmp    f0100ffe <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fdc:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100fdf:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100fe3:	eb 19                	jmp    f0100ffe <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fe5:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100fe8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100fef:	eb 0d                	jmp    f0100ffe <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100ff1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ff4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100ff7:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ffe:	0f b6 06             	movzbl (%esi),%eax
f0101001:	0f b6 d0             	movzbl %al,%edx
f0101004:	8d 7e 01             	lea    0x1(%esi),%edi
f0101007:	89 7d e0             	mov    %edi,-0x20(%ebp)
f010100a:	83 e8 23             	sub    $0x23,%eax
f010100d:	3c 55                	cmp    $0x55,%al
f010100f:	0f 87 d9 02 00 00    	ja     f01012ee <vprintfmt+0x36a>
f0101015:	0f b6 c0             	movzbl %al,%eax
f0101018:	ff 24 85 e4 22 10 f0 	jmp    *-0xfefdd1c(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f010101f:	83 ea 30             	sub    $0x30,%edx
f0101022:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f0101025:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0101029:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010102c:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f010102f:	83 fa 09             	cmp    $0x9,%edx
f0101032:	77 4a                	ja     f010107e <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101034:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101037:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f010103a:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f010103d:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0101041:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0101044:	8d 50 d0             	lea    -0x30(%eax),%edx
f0101047:	83 fa 09             	cmp    $0x9,%edx
f010104a:	76 eb                	jbe    f0101037 <vprintfmt+0xb3>
f010104c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010104f:	eb 2d                	jmp    f010107e <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101051:	8b 45 14             	mov    0x14(%ebp),%eax
f0101054:	8d 50 04             	lea    0x4(%eax),%edx
f0101057:	89 55 14             	mov    %edx,0x14(%ebp)
f010105a:	8b 00                	mov    (%eax),%eax
f010105c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010105f:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0101062:	eb 1a                	jmp    f010107e <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101064:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f0101067:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010106b:	79 91                	jns    f0100ffe <vprintfmt+0x7a>
f010106d:	e9 73 ff ff ff       	jmp    f0100fe5 <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101072:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0101075:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f010107c:	eb 80                	jmp    f0100ffe <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f010107e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101082:	0f 89 76 ff ff ff    	jns    f0100ffe <vprintfmt+0x7a>
f0101088:	e9 64 ff ff ff       	jmp    f0100ff1 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f010108d:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101090:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0101093:	e9 66 ff ff ff       	jmp    f0100ffe <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101098:	8b 45 14             	mov    0x14(%ebp),%eax
f010109b:	8d 50 04             	lea    0x4(%eax),%edx
f010109e:	89 55 14             	mov    %edx,0x14(%ebp)
f01010a1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010a5:	8b 00                	mov    (%eax),%eax
f01010a7:	89 04 24             	mov    %eax,(%esp)
f01010aa:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010ad:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01010b0:	e9 f2 fe ff ff       	jmp    f0100fa7 <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01010b5:	8b 45 14             	mov    0x14(%ebp),%eax
f01010b8:	8d 50 04             	lea    0x4(%eax),%edx
f01010bb:	89 55 14             	mov    %edx,0x14(%ebp)
f01010be:	8b 00                	mov    (%eax),%eax
f01010c0:	89 c2                	mov    %eax,%edx
f01010c2:	c1 fa 1f             	sar    $0x1f,%edx
f01010c5:	31 d0                	xor    %edx,%eax
f01010c7:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01010c9:	83 f8 06             	cmp    $0x6,%eax
f01010cc:	7f 0b                	jg     f01010d9 <vprintfmt+0x155>
f01010ce:	8b 14 85 3c 24 10 f0 	mov    -0xfefdbc4(,%eax,4),%edx
f01010d5:	85 d2                	test   %edx,%edx
f01010d7:	75 23                	jne    f01010fc <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f01010d9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01010dd:	c7 44 24 08 6d 22 10 	movl   $0xf010226d,0x8(%esp)
f01010e4:	f0 
f01010e5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010e9:	8b 7d 08             	mov    0x8(%ebp),%edi
f01010ec:	89 3c 24             	mov    %edi,(%esp)
f01010ef:	e8 68 fe ff ff       	call   f0100f5c <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010f4:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01010f7:	e9 ab fe ff ff       	jmp    f0100fa7 <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f01010fc:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101100:	c7 44 24 08 76 22 10 	movl   $0xf0102276,0x8(%esp)
f0101107:	f0 
f0101108:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010110c:	8b 7d 08             	mov    0x8(%ebp),%edi
f010110f:	89 3c 24             	mov    %edi,(%esp)
f0101112:	e8 45 fe ff ff       	call   f0100f5c <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101117:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010111a:	e9 88 fe ff ff       	jmp    f0100fa7 <vprintfmt+0x23>
f010111f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101122:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101125:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101128:	8b 45 14             	mov    0x14(%ebp),%eax
f010112b:	8d 50 04             	lea    0x4(%eax),%edx
f010112e:	89 55 14             	mov    %edx,0x14(%ebp)
f0101131:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0101133:	85 f6                	test   %esi,%esi
f0101135:	ba 66 22 10 f0       	mov    $0xf0102266,%edx
f010113a:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f010113d:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0101141:	7e 06                	jle    f0101149 <vprintfmt+0x1c5>
f0101143:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0101147:	75 10                	jne    f0101159 <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101149:	0f be 06             	movsbl (%esi),%eax
f010114c:	83 c6 01             	add    $0x1,%esi
f010114f:	85 c0                	test   %eax,%eax
f0101151:	0f 85 86 00 00 00    	jne    f01011dd <vprintfmt+0x259>
f0101157:	eb 76                	jmp    f01011cf <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101159:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010115d:	89 34 24             	mov    %esi,(%esp)
f0101160:	e8 26 03 00 00       	call   f010148b <strnlen>
f0101165:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101168:	29 c2                	sub    %eax,%edx
f010116a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010116d:	85 d2                	test   %edx,%edx
f010116f:	7e d8                	jle    f0101149 <vprintfmt+0x1c5>
					putch(padc, putdat);
f0101171:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0101175:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0101178:	89 7d d0             	mov    %edi,-0x30(%ebp)
f010117b:	89 d6                	mov    %edx,%esi
f010117d:	89 c7                	mov    %eax,%edi
f010117f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101183:	89 3c 24             	mov    %edi,(%esp)
f0101186:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101189:	83 ee 01             	sub    $0x1,%esi
f010118c:	75 f1                	jne    f010117f <vprintfmt+0x1fb>
f010118e:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0101191:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0101194:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101197:	eb b0                	jmp    f0101149 <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101199:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010119d:	74 18                	je     f01011b7 <vprintfmt+0x233>
f010119f:	8d 50 e0             	lea    -0x20(%eax),%edx
f01011a2:	83 fa 5e             	cmp    $0x5e,%edx
f01011a5:	76 10                	jbe    f01011b7 <vprintfmt+0x233>
					putch('?', putdat);
f01011a7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011ab:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01011b2:	ff 55 08             	call   *0x8(%ebp)
f01011b5:	eb 0a                	jmp    f01011c1 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f01011b7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011bb:	89 04 24             	mov    %eax,(%esp)
f01011be:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01011c1:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f01011c5:	0f be 06             	movsbl (%esi),%eax
f01011c8:	83 c6 01             	add    $0x1,%esi
f01011cb:	85 c0                	test   %eax,%eax
f01011cd:	75 0e                	jne    f01011dd <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011cf:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01011d2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01011d6:	7f 11                	jg     f01011e9 <vprintfmt+0x265>
f01011d8:	e9 ca fd ff ff       	jmp    f0100fa7 <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01011dd:	85 ff                	test   %edi,%edi
f01011df:	90                   	nop
f01011e0:	78 b7                	js     f0101199 <vprintfmt+0x215>
f01011e2:	83 ef 01             	sub    $0x1,%edi
f01011e5:	79 b2                	jns    f0101199 <vprintfmt+0x215>
f01011e7:	eb e6                	jmp    f01011cf <vprintfmt+0x24b>
f01011e9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01011ec:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01011ef:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011f3:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01011fa:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01011fc:	83 ee 01             	sub    $0x1,%esi
f01011ff:	75 ee                	jne    f01011ef <vprintfmt+0x26b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101201:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101204:	e9 9e fd ff ff       	jmp    f0100fa7 <vprintfmt+0x23>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101209:	89 ca                	mov    %ecx,%edx
f010120b:	8d 45 14             	lea    0x14(%ebp),%eax
f010120e:	e8 f2 fc ff ff       	call   f0100f05 <getint>
f0101213:	89 c6                	mov    %eax,%esi
f0101215:	89 d7                	mov    %edx,%edi
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101217:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010121c:	85 d2                	test   %edx,%edx
f010121e:	0f 89 8c 00 00 00    	jns    f01012b0 <vprintfmt+0x32c>
				putch('-', putdat);
f0101224:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101228:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010122f:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101232:	f7 de                	neg    %esi
f0101234:	83 d7 00             	adc    $0x0,%edi
f0101237:	f7 df                	neg    %edi
			}
			base = 10;
f0101239:	b8 0a 00 00 00       	mov    $0xa,%eax
f010123e:	eb 70                	jmp    f01012b0 <vprintfmt+0x32c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101240:	89 ca                	mov    %ecx,%edx
f0101242:	8d 45 14             	lea    0x14(%ebp),%eax
f0101245:	e8 81 fc ff ff       	call   f0100ecb <getuint>
f010124a:	89 c6                	mov    %eax,%esi
f010124c:	89 d7                	mov    %edx,%edi
			base = 10;
f010124e:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f0101253:	eb 5b                	jmp    f01012b0 <vprintfmt+0x32c>
			// Replace this with your code.
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
			num = getint(&ap, lflag);
f0101255:	89 ca                	mov    %ecx,%edx
f0101257:	8d 45 14             	lea    0x14(%ebp),%eax
f010125a:	e8 a6 fc ff ff       	call   f0100f05 <getint>
f010125f:	89 c6                	mov    %eax,%esi
f0101261:	89 d7                	mov    %edx,%edi
			base = 8;
f0101263:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0101268:	eb 46                	jmp    f01012b0 <vprintfmt+0x32c>

		// pointer
		case 'p':
			putch('0', putdat);
f010126a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010126e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101275:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101278:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010127c:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101283:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101286:	8b 45 14             	mov    0x14(%ebp),%eax
f0101289:	8d 50 04             	lea    0x4(%eax),%edx
f010128c:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010128f:	8b 30                	mov    (%eax),%esi
f0101291:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101296:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f010129b:	eb 13                	jmp    f01012b0 <vprintfmt+0x32c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010129d:	89 ca                	mov    %ecx,%edx
f010129f:	8d 45 14             	lea    0x14(%ebp),%eax
f01012a2:	e8 24 fc ff ff       	call   f0100ecb <getuint>
f01012a7:	89 c6                	mov    %eax,%esi
f01012a9:	89 d7                	mov    %edx,%edi
			base = 16;
f01012ab:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01012b0:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f01012b4:	89 54 24 10          	mov    %edx,0x10(%esp)
f01012b8:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01012bb:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01012bf:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012c3:	89 34 24             	mov    %esi,(%esp)
f01012c6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01012ca:	89 da                	mov    %ebx,%edx
f01012cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01012cf:	e8 1c fb ff ff       	call   f0100df0 <printnum>
			break;
f01012d4:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01012d7:	e9 cb fc ff ff       	jmp    f0100fa7 <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01012dc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012e0:	89 14 24             	mov    %edx,(%esp)
f01012e3:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012e6:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01012e9:	e9 b9 fc ff ff       	jmp    f0100fa7 <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01012ee:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012f2:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01012f9:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01012fc:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101300:	0f 84 a1 fc ff ff    	je     f0100fa7 <vprintfmt+0x23>
f0101306:	83 ee 01             	sub    $0x1,%esi
f0101309:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f010130d:	75 f7                	jne    f0101306 <vprintfmt+0x382>
f010130f:	e9 93 fc ff ff       	jmp    f0100fa7 <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f0101314:	83 c4 4c             	add    $0x4c,%esp
f0101317:	5b                   	pop    %ebx
f0101318:	5e                   	pop    %esi
f0101319:	5f                   	pop    %edi
f010131a:	5d                   	pop    %ebp
f010131b:	c3                   	ret    

f010131c <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010131c:	55                   	push   %ebp
f010131d:	89 e5                	mov    %esp,%ebp
f010131f:	83 ec 28             	sub    $0x28,%esp
f0101322:	8b 45 08             	mov    0x8(%ebp),%eax
f0101325:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101328:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010132b:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010132f:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101332:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101339:	85 c0                	test   %eax,%eax
f010133b:	74 30                	je     f010136d <vsnprintf+0x51>
f010133d:	85 d2                	test   %edx,%edx
f010133f:	7e 2c                	jle    f010136d <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101341:	8b 45 14             	mov    0x14(%ebp),%eax
f0101344:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101348:	8b 45 10             	mov    0x10(%ebp),%eax
f010134b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010134f:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101352:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101356:	c7 04 24 3f 0f 10 f0 	movl   $0xf0100f3f,(%esp)
f010135d:	e8 22 fc ff ff       	call   f0100f84 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101362:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101365:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101368:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010136b:	eb 05                	jmp    f0101372 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010136d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101372:	c9                   	leave  
f0101373:	c3                   	ret    

f0101374 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101374:	55                   	push   %ebp
f0101375:	89 e5                	mov    %esp,%ebp
f0101377:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010137a:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010137d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101381:	8b 45 10             	mov    0x10(%ebp),%eax
f0101384:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101388:	8b 45 0c             	mov    0xc(%ebp),%eax
f010138b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010138f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101392:	89 04 24             	mov    %eax,(%esp)
f0101395:	e8 82 ff ff ff       	call   f010131c <vsnprintf>
	va_end(ap);

	return rc;
}
f010139a:	c9                   	leave  
f010139b:	c3                   	ret    
f010139c:	00 00                	add    %al,(%eax)
	...

f01013a0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01013a0:	55                   	push   %ebp
f01013a1:	89 e5                	mov    %esp,%ebp
f01013a3:	57                   	push   %edi
f01013a4:	56                   	push   %esi
f01013a5:	53                   	push   %ebx
f01013a6:	83 ec 1c             	sub    $0x1c,%esp
f01013a9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01013ac:	85 c0                	test   %eax,%eax
f01013ae:	74 10                	je     f01013c0 <readline+0x20>
		cprintf("%s", prompt);
f01013b0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013b4:	c7 04 24 76 22 10 f0 	movl   $0xf0102276,(%esp)
f01013bb:	e8 d2 f6 ff ff       	call   f0100a92 <cprintf>

	i = 0;
	echoing = iscons(0);
f01013c0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013c7:	e8 a6 f2 ff ff       	call   f0100672 <iscons>
f01013cc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01013ce:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01013d3:	e8 89 f2 ff ff       	call   f0100661 <getchar>
f01013d8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01013da:	85 c0                	test   %eax,%eax
f01013dc:	79 17                	jns    f01013f5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01013de:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013e2:	c7 04 24 58 24 10 f0 	movl   $0xf0102458,(%esp)
f01013e9:	e8 a4 f6 ff ff       	call   f0100a92 <cprintf>
			return NULL;
f01013ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01013f3:	eb 6d                	jmp    f0101462 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01013f5:	83 f8 08             	cmp    $0x8,%eax
f01013f8:	74 05                	je     f01013ff <readline+0x5f>
f01013fa:	83 f8 7f             	cmp    $0x7f,%eax
f01013fd:	75 19                	jne    f0101418 <readline+0x78>
f01013ff:	85 f6                	test   %esi,%esi
f0101401:	7e 15                	jle    f0101418 <readline+0x78>
			if (echoing)
f0101403:	85 ff                	test   %edi,%edi
f0101405:	74 0c                	je     f0101413 <readline+0x73>
				cputchar('\b');
f0101407:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010140e:	e8 3e f2 ff ff       	call   f0100651 <cputchar>
			i--;
f0101413:	83 ee 01             	sub    $0x1,%esi
f0101416:	eb bb                	jmp    f01013d3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101418:	83 fb 1f             	cmp    $0x1f,%ebx
f010141b:	7e 1f                	jle    f010143c <readline+0x9c>
f010141d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101423:	7f 17                	jg     f010143c <readline+0x9c>
			if (echoing)
f0101425:	85 ff                	test   %edi,%edi
f0101427:	74 08                	je     f0101431 <readline+0x91>
				cputchar(c);
f0101429:	89 1c 24             	mov    %ebx,(%esp)
f010142c:	e8 20 f2 ff ff       	call   f0100651 <cputchar>
			buf[i++] = c;
f0101431:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101437:	83 c6 01             	add    $0x1,%esi
f010143a:	eb 97                	jmp    f01013d3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010143c:	83 fb 0a             	cmp    $0xa,%ebx
f010143f:	74 05                	je     f0101446 <readline+0xa6>
f0101441:	83 fb 0d             	cmp    $0xd,%ebx
f0101444:	75 8d                	jne    f01013d3 <readline+0x33>
			if (echoing)
f0101446:	85 ff                	test   %edi,%edi
f0101448:	74 0c                	je     f0101456 <readline+0xb6>
				cputchar('\n');
f010144a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101451:	e8 fb f1 ff ff       	call   f0100651 <cputchar>
			buf[i] = 0;
f0101456:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010145d:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101462:	83 c4 1c             	add    $0x1c,%esp
f0101465:	5b                   	pop    %ebx
f0101466:	5e                   	pop    %esi
f0101467:	5f                   	pop    %edi
f0101468:	5d                   	pop    %ebp
f0101469:	c3                   	ret    
f010146a:	00 00                	add    %al,(%eax)
f010146c:	00 00                	add    %al,(%eax)
	...

f0101470 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101470:	55                   	push   %ebp
f0101471:	89 e5                	mov    %esp,%ebp
f0101473:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101476:	b8 00 00 00 00       	mov    $0x0,%eax
f010147b:	80 3a 00             	cmpb   $0x0,(%edx)
f010147e:	74 09                	je     f0101489 <strlen+0x19>
		n++;
f0101480:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101483:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101487:	75 f7                	jne    f0101480 <strlen+0x10>
		n++;
	return n;
}
f0101489:	5d                   	pop    %ebp
f010148a:	c3                   	ret    

f010148b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010148b:	55                   	push   %ebp
f010148c:	89 e5                	mov    %esp,%ebp
f010148e:	53                   	push   %ebx
f010148f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101492:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101495:	b8 00 00 00 00       	mov    $0x0,%eax
f010149a:	85 c9                	test   %ecx,%ecx
f010149c:	74 1a                	je     f01014b8 <strnlen+0x2d>
f010149e:	80 3b 00             	cmpb   $0x0,(%ebx)
f01014a1:	74 15                	je     f01014b8 <strnlen+0x2d>
f01014a3:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01014a8:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014aa:	39 ca                	cmp    %ecx,%edx
f01014ac:	74 0a                	je     f01014b8 <strnlen+0x2d>
f01014ae:	83 c2 01             	add    $0x1,%edx
f01014b1:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01014b6:	75 f0                	jne    f01014a8 <strnlen+0x1d>
		n++;
	return n;
}
f01014b8:	5b                   	pop    %ebx
f01014b9:	5d                   	pop    %ebp
f01014ba:	c3                   	ret    

f01014bb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01014bb:	55                   	push   %ebp
f01014bc:	89 e5                	mov    %esp,%ebp
f01014be:	53                   	push   %ebx
f01014bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01014c2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01014c5:	ba 00 00 00 00       	mov    $0x0,%edx
f01014ca:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01014ce:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01014d1:	83 c2 01             	add    $0x1,%edx
f01014d4:	84 c9                	test   %cl,%cl
f01014d6:	75 f2                	jne    f01014ca <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01014d8:	5b                   	pop    %ebx
f01014d9:	5d                   	pop    %ebp
f01014da:	c3                   	ret    

f01014db <strcat>:

char *
strcat(char *dst, const char *src)
{
f01014db:	55                   	push   %ebp
f01014dc:	89 e5                	mov    %esp,%ebp
f01014de:	53                   	push   %ebx
f01014df:	83 ec 08             	sub    $0x8,%esp
f01014e2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01014e5:	89 1c 24             	mov    %ebx,(%esp)
f01014e8:	e8 83 ff ff ff       	call   f0101470 <strlen>
	strcpy(dst + len, src);
f01014ed:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014f0:	89 54 24 04          	mov    %edx,0x4(%esp)
f01014f4:	01 d8                	add    %ebx,%eax
f01014f6:	89 04 24             	mov    %eax,(%esp)
f01014f9:	e8 bd ff ff ff       	call   f01014bb <strcpy>
	return dst;
}
f01014fe:	89 d8                	mov    %ebx,%eax
f0101500:	83 c4 08             	add    $0x8,%esp
f0101503:	5b                   	pop    %ebx
f0101504:	5d                   	pop    %ebp
f0101505:	c3                   	ret    

f0101506 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101506:	55                   	push   %ebp
f0101507:	89 e5                	mov    %esp,%ebp
f0101509:	56                   	push   %esi
f010150a:	53                   	push   %ebx
f010150b:	8b 45 08             	mov    0x8(%ebp),%eax
f010150e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101511:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101514:	85 f6                	test   %esi,%esi
f0101516:	74 18                	je     f0101530 <strncpy+0x2a>
f0101518:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f010151d:	0f b6 1a             	movzbl (%edx),%ebx
f0101520:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101523:	80 3a 01             	cmpb   $0x1,(%edx)
f0101526:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101529:	83 c1 01             	add    $0x1,%ecx
f010152c:	39 f1                	cmp    %esi,%ecx
f010152e:	75 ed                	jne    f010151d <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101530:	5b                   	pop    %ebx
f0101531:	5e                   	pop    %esi
f0101532:	5d                   	pop    %ebp
f0101533:	c3                   	ret    

f0101534 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101534:	55                   	push   %ebp
f0101535:	89 e5                	mov    %esp,%ebp
f0101537:	57                   	push   %edi
f0101538:	56                   	push   %esi
f0101539:	53                   	push   %ebx
f010153a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010153d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101540:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101543:	89 f8                	mov    %edi,%eax
f0101545:	85 f6                	test   %esi,%esi
f0101547:	74 2b                	je     f0101574 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0101549:	83 fe 01             	cmp    $0x1,%esi
f010154c:	74 23                	je     f0101571 <strlcpy+0x3d>
f010154e:	0f b6 0b             	movzbl (%ebx),%ecx
f0101551:	84 c9                	test   %cl,%cl
f0101553:	74 1c                	je     f0101571 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0101555:	83 ee 02             	sub    $0x2,%esi
f0101558:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010155d:	88 08                	mov    %cl,(%eax)
f010155f:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101562:	39 f2                	cmp    %esi,%edx
f0101564:	74 0b                	je     f0101571 <strlcpy+0x3d>
f0101566:	83 c2 01             	add    $0x1,%edx
f0101569:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010156d:	84 c9                	test   %cl,%cl
f010156f:	75 ec                	jne    f010155d <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0101571:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101574:	29 f8                	sub    %edi,%eax
}
f0101576:	5b                   	pop    %ebx
f0101577:	5e                   	pop    %esi
f0101578:	5f                   	pop    %edi
f0101579:	5d                   	pop    %ebp
f010157a:	c3                   	ret    

f010157b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010157b:	55                   	push   %ebp
f010157c:	89 e5                	mov    %esp,%ebp
f010157e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101581:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101584:	0f b6 01             	movzbl (%ecx),%eax
f0101587:	84 c0                	test   %al,%al
f0101589:	74 16                	je     f01015a1 <strcmp+0x26>
f010158b:	3a 02                	cmp    (%edx),%al
f010158d:	75 12                	jne    f01015a1 <strcmp+0x26>
		p++, q++;
f010158f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101592:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f0101596:	84 c0                	test   %al,%al
f0101598:	74 07                	je     f01015a1 <strcmp+0x26>
f010159a:	83 c1 01             	add    $0x1,%ecx
f010159d:	3a 02                	cmp    (%edx),%al
f010159f:	74 ee                	je     f010158f <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01015a1:	0f b6 c0             	movzbl %al,%eax
f01015a4:	0f b6 12             	movzbl (%edx),%edx
f01015a7:	29 d0                	sub    %edx,%eax
}
f01015a9:	5d                   	pop    %ebp
f01015aa:	c3                   	ret    

f01015ab <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01015ab:	55                   	push   %ebp
f01015ac:	89 e5                	mov    %esp,%ebp
f01015ae:	53                   	push   %ebx
f01015af:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015b2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01015b5:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01015b8:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01015bd:	85 d2                	test   %edx,%edx
f01015bf:	74 28                	je     f01015e9 <strncmp+0x3e>
f01015c1:	0f b6 01             	movzbl (%ecx),%eax
f01015c4:	84 c0                	test   %al,%al
f01015c6:	74 24                	je     f01015ec <strncmp+0x41>
f01015c8:	3a 03                	cmp    (%ebx),%al
f01015ca:	75 20                	jne    f01015ec <strncmp+0x41>
f01015cc:	83 ea 01             	sub    $0x1,%edx
f01015cf:	74 13                	je     f01015e4 <strncmp+0x39>
		n--, p++, q++;
f01015d1:	83 c1 01             	add    $0x1,%ecx
f01015d4:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01015d7:	0f b6 01             	movzbl (%ecx),%eax
f01015da:	84 c0                	test   %al,%al
f01015dc:	74 0e                	je     f01015ec <strncmp+0x41>
f01015de:	3a 03                	cmp    (%ebx),%al
f01015e0:	74 ea                	je     f01015cc <strncmp+0x21>
f01015e2:	eb 08                	jmp    f01015ec <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01015e4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01015e9:	5b                   	pop    %ebx
f01015ea:	5d                   	pop    %ebp
f01015eb:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01015ec:	0f b6 01             	movzbl (%ecx),%eax
f01015ef:	0f b6 13             	movzbl (%ebx),%edx
f01015f2:	29 d0                	sub    %edx,%eax
f01015f4:	eb f3                	jmp    f01015e9 <strncmp+0x3e>

f01015f6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01015f6:	55                   	push   %ebp
f01015f7:	89 e5                	mov    %esp,%ebp
f01015f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01015fc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101600:	0f b6 10             	movzbl (%eax),%edx
f0101603:	84 d2                	test   %dl,%dl
f0101605:	74 1c                	je     f0101623 <strchr+0x2d>
		if (*s == c)
f0101607:	38 ca                	cmp    %cl,%dl
f0101609:	75 09                	jne    f0101614 <strchr+0x1e>
f010160b:	eb 1b                	jmp    f0101628 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010160d:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0101610:	38 ca                	cmp    %cl,%dl
f0101612:	74 14                	je     f0101628 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101614:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f0101618:	84 d2                	test   %dl,%dl
f010161a:	75 f1                	jne    f010160d <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f010161c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101621:	eb 05                	jmp    f0101628 <strchr+0x32>
f0101623:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101628:	5d                   	pop    %ebp
f0101629:	c3                   	ret    

f010162a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010162a:	55                   	push   %ebp
f010162b:	89 e5                	mov    %esp,%ebp
f010162d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101630:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101634:	0f b6 10             	movzbl (%eax),%edx
f0101637:	84 d2                	test   %dl,%dl
f0101639:	74 14                	je     f010164f <strfind+0x25>
		if (*s == c)
f010163b:	38 ca                	cmp    %cl,%dl
f010163d:	75 06                	jne    f0101645 <strfind+0x1b>
f010163f:	eb 0e                	jmp    f010164f <strfind+0x25>
f0101641:	38 ca                	cmp    %cl,%dl
f0101643:	74 0a                	je     f010164f <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101645:	83 c0 01             	add    $0x1,%eax
f0101648:	0f b6 10             	movzbl (%eax),%edx
f010164b:	84 d2                	test   %dl,%dl
f010164d:	75 f2                	jne    f0101641 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f010164f:	5d                   	pop    %ebp
f0101650:	c3                   	ret    

f0101651 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101651:	55                   	push   %ebp
f0101652:	89 e5                	mov    %esp,%ebp
f0101654:	83 ec 0c             	sub    $0xc,%esp
f0101657:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010165a:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010165d:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101660:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101663:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101666:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101669:	85 c9                	test   %ecx,%ecx
f010166b:	74 30                	je     f010169d <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010166d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101673:	75 25                	jne    f010169a <memset+0x49>
f0101675:	f6 c1 03             	test   $0x3,%cl
f0101678:	75 20                	jne    f010169a <memset+0x49>
		c &= 0xFF;
f010167a:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010167d:	89 d3                	mov    %edx,%ebx
f010167f:	c1 e3 08             	shl    $0x8,%ebx
f0101682:	89 d6                	mov    %edx,%esi
f0101684:	c1 e6 18             	shl    $0x18,%esi
f0101687:	89 d0                	mov    %edx,%eax
f0101689:	c1 e0 10             	shl    $0x10,%eax
f010168c:	09 f0                	or     %esi,%eax
f010168e:	09 d0                	or     %edx,%eax
f0101690:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101692:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101695:	fc                   	cld    
f0101696:	f3 ab                	rep stos %eax,%es:(%edi)
f0101698:	eb 03                	jmp    f010169d <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010169a:	fc                   	cld    
f010169b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010169d:	89 f8                	mov    %edi,%eax
f010169f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01016a2:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01016a5:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01016a8:	89 ec                	mov    %ebp,%esp
f01016aa:	5d                   	pop    %ebp
f01016ab:	c3                   	ret    

f01016ac <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01016ac:	55                   	push   %ebp
f01016ad:	89 e5                	mov    %esp,%ebp
f01016af:	83 ec 08             	sub    $0x8,%esp
f01016b2:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01016b5:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01016b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01016bb:	8b 75 0c             	mov    0xc(%ebp),%esi
f01016be:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01016c1:	39 c6                	cmp    %eax,%esi
f01016c3:	73 36                	jae    f01016fb <memmove+0x4f>
f01016c5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01016c8:	39 d0                	cmp    %edx,%eax
f01016ca:	73 2f                	jae    f01016fb <memmove+0x4f>
		s += n;
		d += n;
f01016cc:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016cf:	f6 c2 03             	test   $0x3,%dl
f01016d2:	75 1b                	jne    f01016ef <memmove+0x43>
f01016d4:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01016da:	75 13                	jne    f01016ef <memmove+0x43>
f01016dc:	f6 c1 03             	test   $0x3,%cl
f01016df:	75 0e                	jne    f01016ef <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01016e1:	83 ef 04             	sub    $0x4,%edi
f01016e4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01016e7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01016ea:	fd                   	std    
f01016eb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01016ed:	eb 09                	jmp    f01016f8 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01016ef:	83 ef 01             	sub    $0x1,%edi
f01016f2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01016f5:	fd                   	std    
f01016f6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01016f8:	fc                   	cld    
f01016f9:	eb 20                	jmp    f010171b <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016fb:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101701:	75 13                	jne    f0101716 <memmove+0x6a>
f0101703:	a8 03                	test   $0x3,%al
f0101705:	75 0f                	jne    f0101716 <memmove+0x6a>
f0101707:	f6 c1 03             	test   $0x3,%cl
f010170a:	75 0a                	jne    f0101716 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010170c:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010170f:	89 c7                	mov    %eax,%edi
f0101711:	fc                   	cld    
f0101712:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101714:	eb 05                	jmp    f010171b <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101716:	89 c7                	mov    %eax,%edi
f0101718:	fc                   	cld    
f0101719:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010171b:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010171e:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101721:	89 ec                	mov    %ebp,%esp
f0101723:	5d                   	pop    %ebp
f0101724:	c3                   	ret    

f0101725 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101725:	55                   	push   %ebp
f0101726:	89 e5                	mov    %esp,%ebp
f0101728:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010172b:	8b 45 10             	mov    0x10(%ebp),%eax
f010172e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101732:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101735:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101739:	8b 45 08             	mov    0x8(%ebp),%eax
f010173c:	89 04 24             	mov    %eax,(%esp)
f010173f:	e8 68 ff ff ff       	call   f01016ac <memmove>
}
f0101744:	c9                   	leave  
f0101745:	c3                   	ret    

f0101746 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101746:	55                   	push   %ebp
f0101747:	89 e5                	mov    %esp,%ebp
f0101749:	57                   	push   %edi
f010174a:	56                   	push   %esi
f010174b:	53                   	push   %ebx
f010174c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010174f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101752:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101755:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010175a:	85 ff                	test   %edi,%edi
f010175c:	74 37                	je     f0101795 <memcmp+0x4f>
		if (*s1 != *s2)
f010175e:	0f b6 03             	movzbl (%ebx),%eax
f0101761:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101764:	83 ef 01             	sub    $0x1,%edi
f0101767:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f010176c:	38 c8                	cmp    %cl,%al
f010176e:	74 1c                	je     f010178c <memcmp+0x46>
f0101770:	eb 10                	jmp    f0101782 <memcmp+0x3c>
f0101772:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0101777:	83 c2 01             	add    $0x1,%edx
f010177a:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f010177e:	38 c8                	cmp    %cl,%al
f0101780:	74 0a                	je     f010178c <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0101782:	0f b6 c0             	movzbl %al,%eax
f0101785:	0f b6 c9             	movzbl %cl,%ecx
f0101788:	29 c8                	sub    %ecx,%eax
f010178a:	eb 09                	jmp    f0101795 <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010178c:	39 fa                	cmp    %edi,%edx
f010178e:	75 e2                	jne    f0101772 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101790:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101795:	5b                   	pop    %ebx
f0101796:	5e                   	pop    %esi
f0101797:	5f                   	pop    %edi
f0101798:	5d                   	pop    %ebp
f0101799:	c3                   	ret    

f010179a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010179a:	55                   	push   %ebp
f010179b:	89 e5                	mov    %esp,%ebp
f010179d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01017a0:	89 c2                	mov    %eax,%edx
f01017a2:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01017a5:	39 d0                	cmp    %edx,%eax
f01017a7:	73 19                	jae    f01017c2 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f01017a9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f01017ad:	38 08                	cmp    %cl,(%eax)
f01017af:	75 06                	jne    f01017b7 <memfind+0x1d>
f01017b1:	eb 0f                	jmp    f01017c2 <memfind+0x28>
f01017b3:	38 08                	cmp    %cl,(%eax)
f01017b5:	74 0b                	je     f01017c2 <memfind+0x28>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01017b7:	83 c0 01             	add    $0x1,%eax
f01017ba:	39 d0                	cmp    %edx,%eax
f01017bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017c0:	75 f1                	jne    f01017b3 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01017c2:	5d                   	pop    %ebp
f01017c3:	c3                   	ret    

f01017c4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01017c4:	55                   	push   %ebp
f01017c5:	89 e5                	mov    %esp,%ebp
f01017c7:	57                   	push   %edi
f01017c8:	56                   	push   %esi
f01017c9:	53                   	push   %ebx
f01017ca:	8b 55 08             	mov    0x8(%ebp),%edx
f01017cd:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01017d0:	0f b6 02             	movzbl (%edx),%eax
f01017d3:	3c 20                	cmp    $0x20,%al
f01017d5:	74 04                	je     f01017db <strtol+0x17>
f01017d7:	3c 09                	cmp    $0x9,%al
f01017d9:	75 0e                	jne    f01017e9 <strtol+0x25>
		s++;
f01017db:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01017de:	0f b6 02             	movzbl (%edx),%eax
f01017e1:	3c 20                	cmp    $0x20,%al
f01017e3:	74 f6                	je     f01017db <strtol+0x17>
f01017e5:	3c 09                	cmp    $0x9,%al
f01017e7:	74 f2                	je     f01017db <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f01017e9:	3c 2b                	cmp    $0x2b,%al
f01017eb:	75 0a                	jne    f01017f7 <strtol+0x33>
		s++;
f01017ed:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01017f0:	bf 00 00 00 00       	mov    $0x0,%edi
f01017f5:	eb 10                	jmp    f0101807 <strtol+0x43>
f01017f7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01017fc:	3c 2d                	cmp    $0x2d,%al
f01017fe:	75 07                	jne    f0101807 <strtol+0x43>
		s++, neg = 1;
f0101800:	83 c2 01             	add    $0x1,%edx
f0101803:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101807:	85 db                	test   %ebx,%ebx
f0101809:	0f 94 c0             	sete   %al
f010180c:	74 05                	je     f0101813 <strtol+0x4f>
f010180e:	83 fb 10             	cmp    $0x10,%ebx
f0101811:	75 15                	jne    f0101828 <strtol+0x64>
f0101813:	80 3a 30             	cmpb   $0x30,(%edx)
f0101816:	75 10                	jne    f0101828 <strtol+0x64>
f0101818:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010181c:	75 0a                	jne    f0101828 <strtol+0x64>
		s += 2, base = 16;
f010181e:	83 c2 02             	add    $0x2,%edx
f0101821:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101826:	eb 13                	jmp    f010183b <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0101828:	84 c0                	test   %al,%al
f010182a:	74 0f                	je     f010183b <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010182c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101831:	80 3a 30             	cmpb   $0x30,(%edx)
f0101834:	75 05                	jne    f010183b <strtol+0x77>
		s++, base = 8;
f0101836:	83 c2 01             	add    $0x1,%edx
f0101839:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f010183b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101840:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101842:	0f b6 0a             	movzbl (%edx),%ecx
f0101845:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101848:	80 fb 09             	cmp    $0x9,%bl
f010184b:	77 08                	ja     f0101855 <strtol+0x91>
			dig = *s - '0';
f010184d:	0f be c9             	movsbl %cl,%ecx
f0101850:	83 e9 30             	sub    $0x30,%ecx
f0101853:	eb 1e                	jmp    f0101873 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0101855:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0101858:	80 fb 19             	cmp    $0x19,%bl
f010185b:	77 08                	ja     f0101865 <strtol+0xa1>
			dig = *s - 'a' + 10;
f010185d:	0f be c9             	movsbl %cl,%ecx
f0101860:	83 e9 57             	sub    $0x57,%ecx
f0101863:	eb 0e                	jmp    f0101873 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0101865:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0101868:	80 fb 19             	cmp    $0x19,%bl
f010186b:	77 14                	ja     f0101881 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010186d:	0f be c9             	movsbl %cl,%ecx
f0101870:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101873:	39 f1                	cmp    %esi,%ecx
f0101875:	7d 0e                	jge    f0101885 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0101877:	83 c2 01             	add    $0x1,%edx
f010187a:	0f af c6             	imul   %esi,%eax
f010187d:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f010187f:	eb c1                	jmp    f0101842 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0101881:	89 c1                	mov    %eax,%ecx
f0101883:	eb 02                	jmp    f0101887 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101885:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0101887:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010188b:	74 05                	je     f0101892 <strtol+0xce>
		*endptr = (char *) s;
f010188d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101890:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101892:	89 ca                	mov    %ecx,%edx
f0101894:	f7 da                	neg    %edx
f0101896:	85 ff                	test   %edi,%edi
f0101898:	0f 45 c2             	cmovne %edx,%eax
}
f010189b:	5b                   	pop    %ebx
f010189c:	5e                   	pop    %esi
f010189d:	5f                   	pop    %edi
f010189e:	5d                   	pop    %ebp
f010189f:	c3                   	ret    

f01018a0 <__udivdi3>:
f01018a0:	83 ec 1c             	sub    $0x1c,%esp
f01018a3:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01018a7:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f01018ab:	8b 44 24 20          	mov    0x20(%esp),%eax
f01018af:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01018b3:	89 74 24 10          	mov    %esi,0x10(%esp)
f01018b7:	8b 74 24 24          	mov    0x24(%esp),%esi
f01018bb:	85 ff                	test   %edi,%edi
f01018bd:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f01018c1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01018c5:	89 cd                	mov    %ecx,%ebp
f01018c7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018cb:	75 33                	jne    f0101900 <__udivdi3+0x60>
f01018cd:	39 f1                	cmp    %esi,%ecx
f01018cf:	77 57                	ja     f0101928 <__udivdi3+0x88>
f01018d1:	85 c9                	test   %ecx,%ecx
f01018d3:	75 0b                	jne    f01018e0 <__udivdi3+0x40>
f01018d5:	b8 01 00 00 00       	mov    $0x1,%eax
f01018da:	31 d2                	xor    %edx,%edx
f01018dc:	f7 f1                	div    %ecx
f01018de:	89 c1                	mov    %eax,%ecx
f01018e0:	89 f0                	mov    %esi,%eax
f01018e2:	31 d2                	xor    %edx,%edx
f01018e4:	f7 f1                	div    %ecx
f01018e6:	89 c6                	mov    %eax,%esi
f01018e8:	8b 44 24 04          	mov    0x4(%esp),%eax
f01018ec:	f7 f1                	div    %ecx
f01018ee:	89 f2                	mov    %esi,%edx
f01018f0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01018f4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01018f8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01018fc:	83 c4 1c             	add    $0x1c,%esp
f01018ff:	c3                   	ret    
f0101900:	31 d2                	xor    %edx,%edx
f0101902:	31 c0                	xor    %eax,%eax
f0101904:	39 f7                	cmp    %esi,%edi
f0101906:	77 e8                	ja     f01018f0 <__udivdi3+0x50>
f0101908:	0f bd cf             	bsr    %edi,%ecx
f010190b:	83 f1 1f             	xor    $0x1f,%ecx
f010190e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101912:	75 2c                	jne    f0101940 <__udivdi3+0xa0>
f0101914:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0101918:	76 04                	jbe    f010191e <__udivdi3+0x7e>
f010191a:	39 f7                	cmp    %esi,%edi
f010191c:	73 d2                	jae    f01018f0 <__udivdi3+0x50>
f010191e:	31 d2                	xor    %edx,%edx
f0101920:	b8 01 00 00 00       	mov    $0x1,%eax
f0101925:	eb c9                	jmp    f01018f0 <__udivdi3+0x50>
f0101927:	90                   	nop
f0101928:	89 f2                	mov    %esi,%edx
f010192a:	f7 f1                	div    %ecx
f010192c:	31 d2                	xor    %edx,%edx
f010192e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101932:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101936:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010193a:	83 c4 1c             	add    $0x1c,%esp
f010193d:	c3                   	ret    
f010193e:	66 90                	xchg   %ax,%ax
f0101940:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101945:	b8 20 00 00 00       	mov    $0x20,%eax
f010194a:	89 ea                	mov    %ebp,%edx
f010194c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101950:	d3 e7                	shl    %cl,%edi
f0101952:	89 c1                	mov    %eax,%ecx
f0101954:	d3 ea                	shr    %cl,%edx
f0101956:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010195b:	09 fa                	or     %edi,%edx
f010195d:	89 f7                	mov    %esi,%edi
f010195f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101963:	89 f2                	mov    %esi,%edx
f0101965:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101969:	d3 e5                	shl    %cl,%ebp
f010196b:	89 c1                	mov    %eax,%ecx
f010196d:	d3 ef                	shr    %cl,%edi
f010196f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101974:	d3 e2                	shl    %cl,%edx
f0101976:	89 c1                	mov    %eax,%ecx
f0101978:	d3 ee                	shr    %cl,%esi
f010197a:	09 d6                	or     %edx,%esi
f010197c:	89 fa                	mov    %edi,%edx
f010197e:	89 f0                	mov    %esi,%eax
f0101980:	f7 74 24 0c          	divl   0xc(%esp)
f0101984:	89 d7                	mov    %edx,%edi
f0101986:	89 c6                	mov    %eax,%esi
f0101988:	f7 e5                	mul    %ebp
f010198a:	39 d7                	cmp    %edx,%edi
f010198c:	72 22                	jb     f01019b0 <__udivdi3+0x110>
f010198e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0101992:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101997:	d3 e5                	shl    %cl,%ebp
f0101999:	39 c5                	cmp    %eax,%ebp
f010199b:	73 04                	jae    f01019a1 <__udivdi3+0x101>
f010199d:	39 d7                	cmp    %edx,%edi
f010199f:	74 0f                	je     f01019b0 <__udivdi3+0x110>
f01019a1:	89 f0                	mov    %esi,%eax
f01019a3:	31 d2                	xor    %edx,%edx
f01019a5:	e9 46 ff ff ff       	jmp    f01018f0 <__udivdi3+0x50>
f01019aa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01019b0:	8d 46 ff             	lea    -0x1(%esi),%eax
f01019b3:	31 d2                	xor    %edx,%edx
f01019b5:	8b 74 24 10          	mov    0x10(%esp),%esi
f01019b9:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01019bd:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01019c1:	83 c4 1c             	add    $0x1c,%esp
f01019c4:	c3                   	ret    
	...

f01019d0 <__umoddi3>:
f01019d0:	83 ec 1c             	sub    $0x1c,%esp
f01019d3:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f01019d7:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f01019db:	8b 44 24 20          	mov    0x20(%esp),%eax
f01019df:	89 74 24 10          	mov    %esi,0x10(%esp)
f01019e3:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01019e7:	8b 74 24 24          	mov    0x24(%esp),%esi
f01019eb:	85 ed                	test   %ebp,%ebp
f01019ed:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01019f1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019f5:	89 cf                	mov    %ecx,%edi
f01019f7:	89 04 24             	mov    %eax,(%esp)
f01019fa:	89 f2                	mov    %esi,%edx
f01019fc:	75 1a                	jne    f0101a18 <__umoddi3+0x48>
f01019fe:	39 f1                	cmp    %esi,%ecx
f0101a00:	76 4e                	jbe    f0101a50 <__umoddi3+0x80>
f0101a02:	f7 f1                	div    %ecx
f0101a04:	89 d0                	mov    %edx,%eax
f0101a06:	31 d2                	xor    %edx,%edx
f0101a08:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101a0c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101a10:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101a14:	83 c4 1c             	add    $0x1c,%esp
f0101a17:	c3                   	ret    
f0101a18:	39 f5                	cmp    %esi,%ebp
f0101a1a:	77 54                	ja     f0101a70 <__umoddi3+0xa0>
f0101a1c:	0f bd c5             	bsr    %ebp,%eax
f0101a1f:	83 f0 1f             	xor    $0x1f,%eax
f0101a22:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a26:	75 60                	jne    f0101a88 <__umoddi3+0xb8>
f0101a28:	3b 0c 24             	cmp    (%esp),%ecx
f0101a2b:	0f 87 07 01 00 00    	ja     f0101b38 <__umoddi3+0x168>
f0101a31:	89 f2                	mov    %esi,%edx
f0101a33:	8b 34 24             	mov    (%esp),%esi
f0101a36:	29 ce                	sub    %ecx,%esi
f0101a38:	19 ea                	sbb    %ebp,%edx
f0101a3a:	89 34 24             	mov    %esi,(%esp)
f0101a3d:	8b 04 24             	mov    (%esp),%eax
f0101a40:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101a44:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101a48:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101a4c:	83 c4 1c             	add    $0x1c,%esp
f0101a4f:	c3                   	ret    
f0101a50:	85 c9                	test   %ecx,%ecx
f0101a52:	75 0b                	jne    f0101a5f <__umoddi3+0x8f>
f0101a54:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a59:	31 d2                	xor    %edx,%edx
f0101a5b:	f7 f1                	div    %ecx
f0101a5d:	89 c1                	mov    %eax,%ecx
f0101a5f:	89 f0                	mov    %esi,%eax
f0101a61:	31 d2                	xor    %edx,%edx
f0101a63:	f7 f1                	div    %ecx
f0101a65:	8b 04 24             	mov    (%esp),%eax
f0101a68:	f7 f1                	div    %ecx
f0101a6a:	eb 98                	jmp    f0101a04 <__umoddi3+0x34>
f0101a6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a70:	89 f2                	mov    %esi,%edx
f0101a72:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101a76:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101a7a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101a7e:	83 c4 1c             	add    $0x1c,%esp
f0101a81:	c3                   	ret    
f0101a82:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101a88:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a8d:	89 e8                	mov    %ebp,%eax
f0101a8f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0101a94:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0101a98:	89 fa                	mov    %edi,%edx
f0101a9a:	d3 e0                	shl    %cl,%eax
f0101a9c:	89 e9                	mov    %ebp,%ecx
f0101a9e:	d3 ea                	shr    %cl,%edx
f0101aa0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101aa5:	09 c2                	or     %eax,%edx
f0101aa7:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101aab:	89 14 24             	mov    %edx,(%esp)
f0101aae:	89 f2                	mov    %esi,%edx
f0101ab0:	d3 e7                	shl    %cl,%edi
f0101ab2:	89 e9                	mov    %ebp,%ecx
f0101ab4:	d3 ea                	shr    %cl,%edx
f0101ab6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101abb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101abf:	d3 e6                	shl    %cl,%esi
f0101ac1:	89 e9                	mov    %ebp,%ecx
f0101ac3:	d3 e8                	shr    %cl,%eax
f0101ac5:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101aca:	09 f0                	or     %esi,%eax
f0101acc:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101ad0:	f7 34 24             	divl   (%esp)
f0101ad3:	d3 e6                	shl    %cl,%esi
f0101ad5:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101ad9:	89 d6                	mov    %edx,%esi
f0101adb:	f7 e7                	mul    %edi
f0101add:	39 d6                	cmp    %edx,%esi
f0101adf:	89 c1                	mov    %eax,%ecx
f0101ae1:	89 d7                	mov    %edx,%edi
f0101ae3:	72 3f                	jb     f0101b24 <__umoddi3+0x154>
f0101ae5:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101ae9:	72 35                	jb     f0101b20 <__umoddi3+0x150>
f0101aeb:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101aef:	29 c8                	sub    %ecx,%eax
f0101af1:	19 fe                	sbb    %edi,%esi
f0101af3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101af8:	89 f2                	mov    %esi,%edx
f0101afa:	d3 e8                	shr    %cl,%eax
f0101afc:	89 e9                	mov    %ebp,%ecx
f0101afe:	d3 e2                	shl    %cl,%edx
f0101b00:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b05:	09 d0                	or     %edx,%eax
f0101b07:	89 f2                	mov    %esi,%edx
f0101b09:	d3 ea                	shr    %cl,%edx
f0101b0b:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101b0f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101b13:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101b17:	83 c4 1c             	add    $0x1c,%esp
f0101b1a:	c3                   	ret    
f0101b1b:	90                   	nop
f0101b1c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101b20:	39 d6                	cmp    %edx,%esi
f0101b22:	75 c7                	jne    f0101aeb <__umoddi3+0x11b>
f0101b24:	89 d7                	mov    %edx,%edi
f0101b26:	89 c1                	mov    %eax,%ecx
f0101b28:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0101b2c:	1b 3c 24             	sbb    (%esp),%edi
f0101b2f:	eb ba                	jmp    f0101aeb <__umoddi3+0x11b>
f0101b31:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101b38:	39 f5                	cmp    %esi,%ebp
f0101b3a:	0f 82 f1 fe ff ff    	jb     f0101a31 <__umoddi3+0x61>
f0101b40:	e9 f8 fe ff ff       	jmp    f0101a3d <__umoddi3+0x6d>
