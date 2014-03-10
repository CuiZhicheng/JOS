
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start-0xc>:
.long MULTIBOOT_HEADER_FLAGS
.long CHECKSUM

.globl		_start
_start:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 03 00    	add    0x31bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fb                   	sti    
f0100009:	4f                   	dec    %edi
f010000a:	52                   	push   %edx
f010000b:	e4 66                	in     $0x66,%al

f010000c <_start>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 

	# Establish our own GDT in place of the boot loader's temporary GDT.
	lgdt	RELOC(mygdtdesc)		# load descriptor table
f0100015:	0f 01 15 18 20 11 00 	lgdtl  0x112018

	# Immediately reload all segment registers (including CS!)
	# with segment selectors from the new GDT.
	movl	$DATA_SEL, %eax			# Data segment selector
f010001c:	b8 10 00 00 00       	mov    $0x10,%eax
	movw	%ax,%ds				# -> DS: Data Segment
f0100021:	8e d8                	mov    %eax,%ds
	movw	%ax,%es				# -> ES: Extra Segment
f0100023:	8e c0                	mov    %eax,%es
	movw	%ax,%ss				# -> SS: Stack Segment
f0100025:	8e d0                	mov    %eax,%ss
	ljmp	$CODE_SEL,$relocated		# reload CS by jumping
f0100027:	ea 2e 00 10 f0 08 00 	ljmp   $0x8,$0xf010002e

f010002e <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002e:	bd 00 00 00 00       	mov    $0x0,%ebp

        # Set the stack pointer
	movl	$(bootstacktop),%esp
f0100033:	bc 00 20 11 f0       	mov    $0xf0112000,%esp

	# now to C code
	call	i386_init
f0100038:	e8 03 00 00 00       	call   f0100040 <i386_init>

f010003d <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003d:	eb fe                	jmp    f010003d <spin>
	...

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	83 ec 1c             	sub    $0x1c,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100043:	b8 10 2a 11 f0       	mov    $0xf0112a10,%eax
f0100048:	2d 70 23 11 f0       	sub    $0xf0112370,%eax
f010004d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100051:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100058:	00 
f0100059:	c7 04 24 70 23 11 f0 	movl   $0xf0112370,(%esp)
f0100060:	e8 39 19 00 00       	call   f010199e <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100065:	e8 5c 05 00 00       	call   f01005c6 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006a:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100071:	00 
f0100072:	c7 04 24 60 1e 10 f0 	movl   $0xf0101e60,(%esp)
f0100079:	e8 9c 0d 00 00       	call   f0100e1a <cprintf>

	// Lab 2 memory management initialization functions
	i386_detect_memory();
f010007e:	e8 18 08 00 00       	call   f010089b <i386_detect_memory>
	i386_vm_init();
f0100083:	e8 a9 08 00 00       	call   f0100931 <i386_vm_init>



	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100088:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008f:	e8 86 06 00 00       	call   f010071a <monitor>
f0100094:	eb f2                	jmp    f0100088 <i386_init+0x48>

f0100096 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100096:	83 ec 1c             	sub    $0x1c,%esp
	va_list ap;

	if (panicstr)
f0100099:	83 3d 80 23 11 f0 00 	cmpl   $0x0,0xf0112380
f01000a0:	75 45                	jne    f01000e7 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a2:	8b 44 24 28          	mov    0x28(%esp),%eax
f01000a6:	a3 80 23 11 f0       	mov    %eax,0xf0112380

	va_start(ap, fmt);
	cprintf("kernel panic at %s:%d: ", file, line);
f01000ab:	8b 44 24 24          	mov    0x24(%esp),%eax
f01000af:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b3:	8b 44 24 20          	mov    0x20(%esp),%eax
f01000b7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000bb:	c7 04 24 7b 1e 10 f0 	movl   $0xf0101e7b,(%esp)
f01000c2:	e8 53 0d 00 00       	call   f0100e1a <cprintf>
	vcprintf(fmt, ap);
f01000c7:	8d 44 24 2c          	lea    0x2c(%esp),%eax
f01000cb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000cf:	8b 44 24 28          	mov    0x28(%esp),%eax
f01000d3:	89 04 24             	mov    %eax,(%esp)
f01000d6:	e8 08 0d 00 00       	call   f0100de3 <vcprintf>
	cprintf("\n");
f01000db:	c7 04 24 b7 1e 10 f0 	movl   $0xf0101eb7,(%esp)
f01000e2:	e8 33 0d 00 00       	call   f0100e1a <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ee:	e8 27 06 00 00       	call   f010071a <monitor>
f01000f3:	eb f2                	jmp    f01000e7 <_panic+0x51>

f01000f5 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f5:	83 ec 1c             	sub    $0x1c,%esp
	va_list ap;

	va_start(ap, fmt);
	cprintf("kernel warning at %s:%d: ", file, line);
f01000f8:	8b 44 24 24          	mov    0x24(%esp),%eax
f01000fc:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100100:	8b 44 24 20          	mov    0x20(%esp),%eax
f0100104:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100108:	c7 04 24 93 1e 10 f0 	movl   $0xf0101e93,(%esp)
f010010f:	e8 06 0d 00 00       	call   f0100e1a <cprintf>
	vcprintf(fmt, ap);
f0100114:	8d 44 24 2c          	lea    0x2c(%esp),%eax
f0100118:	89 44 24 04          	mov    %eax,0x4(%esp)
f010011c:	8b 44 24 28          	mov    0x28(%esp),%eax
f0100120:	89 04 24             	mov    %eax,(%esp)
f0100123:	e8 bb 0c 00 00       	call   f0100de3 <vcprintf>
	cprintf("\n");
f0100128:	c7 04 24 b7 1e 10 f0 	movl   $0xf0101eb7,(%esp)
f010012f:	e8 e6 0c 00 00       	call   f0100e1a <cprintf>
	va_end(ap);
}
f0100134:	83 c4 1c             	add    $0x1c,%esp
f0100137:	c3                   	ret    
	...

f0100140 <serial_proc_data>:

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100140:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100145:	ec                   	in     (%dx),%al

int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100146:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010014b:	a8 01                	test   $0x1,%al
f010014d:	74 06                	je     f0100155 <serial_proc_data+0x15>
f010014f:	b2 f8                	mov    $0xf8,%dl
f0100151:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100152:	0f b6 c8             	movzbl %al,%ecx
}
f0100155:	89 c8                	mov    %ecx,%eax
f0100157:	c3                   	ret    

f0100158 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100158:	53                   	push   %ebx
f0100159:	83 ec 18             	sub    $0x18,%esp
f010015c:	ba 64 00 00 00       	mov    $0x64,%edx
f0100161:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100162:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100167:	a8 01                	test   $0x1,%al
f0100169:	0f 84 de 00 00 00    	je     f010024d <kbd_proc_data+0xf5>
f010016f:	b2 60                	mov    $0x60,%dl
f0100171:	ec                   	in     (%dx),%al
f0100172:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100174:	3c e0                	cmp    $0xe0,%al
f0100176:	75 11                	jne    f0100189 <kbd_proc_data+0x31>
		// E0 escape character
		shift |= E0ESC;
f0100178:	83 0d b0 23 11 f0 40 	orl    $0x40,0xf01123b0
		return 0;
f010017f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100184:	e9 c4 00 00 00       	jmp    f010024d <kbd_proc_data+0xf5>
	} else if (data & 0x80) {
f0100189:	84 c0                	test   %al,%al
f010018b:	79 37                	jns    f01001c4 <kbd_proc_data+0x6c>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010018d:	8b 0d b0 23 11 f0    	mov    0xf01123b0,%ecx
f0100193:	89 cb                	mov    %ecx,%ebx
f0100195:	83 e3 40             	and    $0x40,%ebx
f0100198:	83 e0 7f             	and    $0x7f,%eax
f010019b:	85 db                	test   %ebx,%ebx
f010019d:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001a0:	0f b6 d2             	movzbl %dl,%edx
f01001a3:	0f b6 82 e0 1e 10 f0 	movzbl -0xfefe120(%edx),%eax
f01001aa:	83 c8 40             	or     $0x40,%eax
f01001ad:	0f b6 c0             	movzbl %al,%eax
f01001b0:	f7 d0                	not    %eax
f01001b2:	21 c1                	and    %eax,%ecx
f01001b4:	89 0d b0 23 11 f0    	mov    %ecx,0xf01123b0
		return 0;
f01001ba:	bb 00 00 00 00       	mov    $0x0,%ebx
f01001bf:	e9 89 00 00 00       	jmp    f010024d <kbd_proc_data+0xf5>
	} else if (shift & E0ESC) {
f01001c4:	8b 0d b0 23 11 f0    	mov    0xf01123b0,%ecx
f01001ca:	f6 c1 40             	test   $0x40,%cl
f01001cd:	74 0e                	je     f01001dd <kbd_proc_data+0x85>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001cf:	89 c2                	mov    %eax,%edx
f01001d1:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f01001d4:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001d7:	89 0d b0 23 11 f0    	mov    %ecx,0xf01123b0
	}

	shift |= shiftcode[data];
f01001dd:	0f b6 d2             	movzbl %dl,%edx
f01001e0:	0f b6 82 e0 1e 10 f0 	movzbl -0xfefe120(%edx),%eax
f01001e7:	0b 05 b0 23 11 f0    	or     0xf01123b0,%eax
	shift ^= togglecode[data];
f01001ed:	0f b6 8a e0 1f 10 f0 	movzbl -0xfefe020(%edx),%ecx
f01001f4:	31 c8                	xor    %ecx,%eax
f01001f6:	a3 b0 23 11 f0       	mov    %eax,0xf01123b0

	c = charcode[shift & (CTL | SHIFT)][data];
f01001fb:	89 c1                	mov    %eax,%ecx
f01001fd:	83 e1 03             	and    $0x3,%ecx
f0100200:	8b 0c 8d e0 20 10 f0 	mov    -0xfefdf20(,%ecx,4),%ecx
f0100207:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f010020b:	a8 08                	test   $0x8,%al
f010020d:	74 19                	je     f0100228 <kbd_proc_data+0xd0>
		if ('a' <= c && c <= 'z')
f010020f:	8d 53 9f             	lea    -0x61(%ebx),%edx
f0100212:	83 fa 19             	cmp    $0x19,%edx
f0100215:	77 05                	ja     f010021c <kbd_proc_data+0xc4>
			c += 'A' - 'a';
f0100217:	83 eb 20             	sub    $0x20,%ebx
f010021a:	eb 0c                	jmp    f0100228 <kbd_proc_data+0xd0>
		else if ('A' <= c && c <= 'Z')
f010021c:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f010021f:	8d 53 20             	lea    0x20(%ebx),%edx
f0100222:	83 f9 19             	cmp    $0x19,%ecx
f0100225:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100228:	f7 d0                	not    %eax
f010022a:	a8 06                	test   $0x6,%al
f010022c:	75 1f                	jne    f010024d <kbd_proc_data+0xf5>
f010022e:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100234:	75 17                	jne    f010024d <kbd_proc_data+0xf5>
		cprintf("Rebooting!\n");
f0100236:	c7 04 24 ad 1e 10 f0 	movl   $0xf0101ead,(%esp)
f010023d:	e8 d8 0b 00 00       	call   f0100e1a <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100242:	ba 92 00 00 00       	mov    $0x92,%edx
f0100247:	b8 03 00 00 00       	mov    $0x3,%eax
f010024c:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010024d:	89 d8                	mov    %ebx,%eax
f010024f:	83 c4 18             	add    $0x18,%esp
f0100252:	5b                   	pop    %ebx
f0100253:	c3                   	ret    

f0100254 <serial_init>:
		cons_intr(serial_proc_data);
}

void
serial_init(void)
{
f0100254:	53                   	push   %ebx
f0100255:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f010025a:	b8 00 00 00 00       	mov    $0x0,%eax
f010025f:	89 da                	mov    %ebx,%edx
f0100261:	ee                   	out    %al,(%dx)
f0100262:	b2 fb                	mov    $0xfb,%dl
f0100264:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100269:	ee                   	out    %al,(%dx)
f010026a:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f010026f:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100274:	89 ca                	mov    %ecx,%edx
f0100276:	ee                   	out    %al,(%dx)
f0100277:	b2 f9                	mov    $0xf9,%dl
f0100279:	b8 00 00 00 00       	mov    $0x0,%eax
f010027e:	ee                   	out    %al,(%dx)
f010027f:	b2 fb                	mov    $0xfb,%dl
f0100281:	b8 03 00 00 00       	mov    $0x3,%eax
f0100286:	ee                   	out    %al,(%dx)
f0100287:	b2 fc                	mov    $0xfc,%dl
f0100289:	b8 00 00 00 00       	mov    $0x0,%eax
f010028e:	ee                   	out    %al,(%dx)
f010028f:	b2 f9                	mov    $0xf9,%dl
f0100291:	b8 01 00 00 00       	mov    $0x1,%eax
f0100296:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100297:	b2 fd                	mov    $0xfd,%dl
f0100299:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010029a:	3c ff                	cmp    $0xff,%al
f010029c:	0f 95 c0             	setne  %al
f010029f:	0f b6 c0             	movzbl %al,%eax
f01002a2:	a3 a0 23 11 f0       	mov    %eax,0xf01123a0
f01002a7:	89 da                	mov    %ebx,%edx
f01002a9:	ec                   	in     (%dx),%al
f01002aa:	89 ca                	mov    %ecx,%edx
f01002ac:	ec                   	in     (%dx),%al
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);

}
f01002ad:	5b                   	pop    %ebx
f01002ae:	c3                   	ret    

f01002af <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
cga_init(void)
{
f01002af:	83 ec 0c             	sub    $0xc,%esp
f01002b2:	89 1c 24             	mov    %ebx,(%esp)
f01002b5:	89 74 24 04          	mov    %esi,0x4(%esp)
f01002b9:	89 7c 24 08          	mov    %edi,0x8(%esp)
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01002bd:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01002c4:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01002cb:	5a a5 
	if (*cp != 0xA55A) {
f01002cd:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01002d4:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01002d8:	74 11                	je     f01002eb <cga_init+0x3c>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01002da:	c7 05 a4 23 11 f0 b4 	movl   $0x3b4,0xf01123a4
f01002e1:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01002e4:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f01002e9:	eb 16                	jmp    f0100301 <cga_init+0x52>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01002eb:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01002f2:	c7 05 a4 23 11 f0 d4 	movl   $0x3d4,0xf01123a4
f01002f9:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01002fc:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100301:	8b 0d a4 23 11 f0    	mov    0xf01123a4,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100307:	b8 0e 00 00 00       	mov    $0xe,%eax
f010030c:	89 ca                	mov    %ecx,%edx
f010030e:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010030f:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100312:	89 da                	mov    %ebx,%edx
f0100314:	ec                   	in     (%dx),%al
f0100315:	0f b6 f8             	movzbl %al,%edi
f0100318:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010031b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100320:	89 ca                	mov    %ecx,%edx
f0100322:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100323:	89 da                	mov    %ebx,%edx
f0100325:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100326:	89 35 a8 23 11 f0    	mov    %esi,0xf01123a8
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010032c:	0f b6 d8             	movzbl %al,%ebx
f010032f:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100331:	66 89 3d ac 23 11 f0 	mov    %di,0xf01123ac
}
f0100338:	8b 1c 24             	mov    (%esp),%ebx
f010033b:	8b 74 24 04          	mov    0x4(%esp),%esi
f010033f:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0100343:	83 c4 0c             	add    $0xc,%esp
f0100346:	c3                   	ret    

f0100347 <kbd_init>:
}

void
kbd_init(void)
{
}
f0100347:	f3 c3                	repz ret 

f0100349 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
f0100349:	53                   	push   %ebx
f010034a:	83 ec 08             	sub    $0x8,%esp
f010034d:	8b 5c 24 10          	mov    0x10(%esp),%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100351:	eb 25                	jmp    f0100378 <cons_intr+0x2f>
		if (c == 0)
f0100353:	85 c0                	test   %eax,%eax
f0100355:	74 21                	je     f0100378 <cons_intr+0x2f>
			continue;
		cons.buf[cons.wpos++] = c;
f0100357:	8b 15 c4 25 11 f0    	mov    0xf01125c4,%edx
f010035d:	88 82 c0 23 11 f0    	mov    %al,-0xfeedc40(%edx)
f0100363:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f0100366:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f010036b:	ba 00 00 00 00       	mov    $0x0,%edx
f0100370:	0f 44 c2             	cmove  %edx,%eax
f0100373:	a3 c4 25 11 f0       	mov    %eax,0xf01125c4
void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100378:	ff d3                	call   *%ebx
f010037a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010037d:	75 d4                	jne    f0100353 <cons_intr+0xa>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010037f:	83 c4 08             	add    $0x8,%esp
f0100382:	5b                   	pop    %ebx
f0100383:	c3                   	ret    

f0100384 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100384:	83 ec 1c             	sub    $0x1c,%esp
	cons_intr(kbd_proc_data);
f0100387:	c7 04 24 58 01 10 f0 	movl   $0xf0100158,(%esp)
f010038e:	e8 b6 ff ff ff       	call   f0100349 <cons_intr>
}
f0100393:	83 c4 1c             	add    $0x1c,%esp
f0100396:	c3                   	ret    

f0100397 <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100397:	83 ec 1c             	sub    $0x1c,%esp
	if (serial_exists)
f010039a:	83 3d a0 23 11 f0 00 	cmpl   $0x0,0xf01123a0
f01003a1:	74 0c                	je     f01003af <serial_intr+0x18>
		cons_intr(serial_proc_data);
f01003a3:	c7 04 24 40 01 10 f0 	movl   $0xf0100140,(%esp)
f01003aa:	e8 9a ff ff ff       	call   f0100349 <cons_intr>
}
f01003af:	83 c4 1c             	add    $0x1c,%esp
f01003b2:	c3                   	ret    

f01003b3 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01003b3:	83 ec 0c             	sub    $0xc,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01003b6:	e8 dc ff ff ff       	call   f0100397 <serial_intr>
	kbd_intr();
f01003bb:	e8 c4 ff ff ff       	call   f0100384 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01003c0:	8b 15 c0 25 11 f0    	mov    0xf01125c0,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f01003c6:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01003cb:	3b 15 c4 25 11 f0    	cmp    0xf01125c4,%edx
f01003d1:	74 1e                	je     f01003f1 <cons_getc+0x3e>
		c = cons.buf[cons.rpos++];
f01003d3:	0f b6 82 c0 23 11 f0 	movzbl -0xfeedc40(%edx),%eax
f01003da:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f01003dd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01003e3:	b9 00 00 00 00       	mov    $0x0,%ecx
f01003e8:	0f 44 d1             	cmove  %ecx,%edx
f01003eb:	89 15 c0 25 11 f0    	mov    %edx,0xf01125c0
		return c;
	}
	return 0;
}
f01003f1:	83 c4 0c             	add    $0xc,%esp
f01003f4:	c3                   	ret    

f01003f5 <cons_putc>:

// output a character to the console
void
cons_putc(int c)
{
f01003f5:	57                   	push   %edi
f01003f6:	56                   	push   %esi
f01003f7:	53                   	push   %ebx
f01003f8:	83 ec 10             	sub    $0x10,%esp
f01003fb:	8b 7c 24 20          	mov    0x20(%esp),%edi
f01003ff:	ba 79 03 00 00       	mov    $0x379,%edx
f0100404:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100405:	84 c0                	test   %al,%al
f0100407:	78 21                	js     f010042a <cons_putc+0x35>
f0100409:	bb 00 32 00 00       	mov    $0x3200,%ebx
f010040e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100413:	be 79 03 00 00       	mov    $0x379,%esi
f0100418:	89 ca                	mov    %ecx,%edx
f010041a:	ec                   	in     (%dx),%al
f010041b:	ec                   	in     (%dx),%al
f010041c:	ec                   	in     (%dx),%al
f010041d:	ec                   	in     (%dx),%al
f010041e:	89 f2                	mov    %esi,%edx
f0100420:	ec                   	in     (%dx),%al
f0100421:	84 c0                	test   %al,%al
f0100423:	78 05                	js     f010042a <cons_putc+0x35>
f0100425:	83 eb 01             	sub    $0x1,%ebx
f0100428:	75 ee                	jne    f0100418 <cons_putc+0x23>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010042a:	ba 78 03 00 00       	mov    $0x378,%edx
f010042f:	89 f8                	mov    %edi,%eax
f0100431:	ee                   	out    %al,(%dx)
f0100432:	b2 7a                	mov    $0x7a,%dl
f0100434:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100439:	ee                   	out    %al,(%dx)
f010043a:	b8 08 00 00 00       	mov    $0x8,%eax
f010043f:	ee                   	out    %al,(%dx)
// output a character to the console
void
cons_putc(int c)
{
	lpt_putc(c);
	cga_putc(c);
f0100440:	89 3c 24             	mov    %edi,(%esp)
f0100443:	e8 07 00 00 00       	call   f010044f <cga_putc>
}
f0100448:	83 c4 10             	add    $0x10,%esp
f010044b:	5b                   	pop    %ebx
f010044c:	5e                   	pop    %esi
f010044d:	5f                   	pop    %edi
f010044e:	c3                   	ret    

f010044f <cga_putc>:



void
cga_putc(int c)
{
f010044f:	56                   	push   %esi
f0100450:	53                   	push   %ebx
f0100451:	83 ec 14             	sub    $0x14,%esp
f0100454:	8b 44 24 20          	mov    0x20(%esp),%eax
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100458:	89 c1                	mov    %eax,%ecx
f010045a:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f0100460:	89 c2                	mov    %eax,%edx
f0100462:	80 ce 07             	or     $0x7,%dh
f0100465:	85 c9                	test   %ecx,%ecx
f0100467:	0f 44 c2             	cmove  %edx,%eax

	switch (c & 0xff) {
f010046a:	0f b6 d0             	movzbl %al,%edx
f010046d:	83 fa 09             	cmp    $0x9,%edx
f0100470:	74 77                	je     f01004e9 <cga_putc+0x9a>
f0100472:	83 fa 09             	cmp    $0x9,%edx
f0100475:	7f 0b                	jg     f0100482 <cga_putc+0x33>
f0100477:	83 fa 08             	cmp    $0x8,%edx
f010047a:	0f 85 a7 00 00 00    	jne    f0100527 <cga_putc+0xd8>
f0100480:	eb 10                	jmp    f0100492 <cga_putc+0x43>
f0100482:	83 fa 0a             	cmp    $0xa,%edx
f0100485:	74 3c                	je     f01004c3 <cga_putc+0x74>
f0100487:	83 fa 0d             	cmp    $0xd,%edx
f010048a:	0f 85 97 00 00 00    	jne    f0100527 <cga_putc+0xd8>
f0100490:	eb 39                	jmp    f01004cb <cga_putc+0x7c>
	case '\b':
		if (crt_pos > 0) {
f0100492:	0f b7 15 ac 23 11 f0 	movzwl 0xf01123ac,%edx
f0100499:	66 85 d2             	test   %dx,%dx
f010049c:	0f 84 f0 00 00 00    	je     f0100592 <cga_putc+0x143>
			crt_pos--;
f01004a2:	83 ea 01             	sub    $0x1,%edx
f01004a5:	66 89 15 ac 23 11 f0 	mov    %dx,0xf01123ac
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004ac:	0f b7 d2             	movzwl %dx,%edx
f01004af:	b0 00                	mov    $0x0,%al
f01004b1:	83 c8 20             	or     $0x20,%eax
f01004b4:	8b 0d a8 23 11 f0    	mov    0xf01123a8,%ecx
f01004ba:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f01004be:	e9 82 00 00 00       	jmp    f0100545 <cga_putc+0xf6>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004c3:	66 83 05 ac 23 11 f0 	addw   $0x50,0xf01123ac
f01004ca:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004cb:	0f b7 05 ac 23 11 f0 	movzwl 0xf01123ac,%eax
f01004d2:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004d8:	c1 e8 16             	shr    $0x16,%eax
f01004db:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004de:	c1 e0 04             	shl    $0x4,%eax
f01004e1:	66 a3 ac 23 11 f0    	mov    %ax,0xf01123ac
		break;
f01004e7:	eb 5c                	jmp    f0100545 <cga_putc+0xf6>
	case '\t':
		cons_putc(' ');
f01004e9:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01004f0:	e8 00 ff ff ff       	call   f01003f5 <cons_putc>
		cons_putc(' ');
f01004f5:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01004fc:	e8 f4 fe ff ff       	call   f01003f5 <cons_putc>
		cons_putc(' ');
f0100501:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100508:	e8 e8 fe ff ff       	call   f01003f5 <cons_putc>
		cons_putc(' ');
f010050d:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100514:	e8 dc fe ff ff       	call   f01003f5 <cons_putc>
		cons_putc(' ');
f0100519:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100520:	e8 d0 fe ff ff       	call   f01003f5 <cons_putc>
		break;
f0100525:	eb 1e                	jmp    f0100545 <cga_putc+0xf6>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100527:	0f b7 15 ac 23 11 f0 	movzwl 0xf01123ac,%edx
f010052e:	0f b7 da             	movzwl %dx,%ebx
f0100531:	8b 0d a8 23 11 f0    	mov    0xf01123a8,%ecx
f0100537:	66 89 04 59          	mov    %ax,(%ecx,%ebx,2)
f010053b:	83 c2 01             	add    $0x1,%edx
f010053e:	66 89 15 ac 23 11 f0 	mov    %dx,0xf01123ac
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100545:	66 81 3d ac 23 11 f0 	cmpw   $0x7cf,0xf01123ac
f010054c:	cf 07 
f010054e:	76 42                	jbe    f0100592 <cga_putc+0x143>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100550:	a1 a8 23 11 f0       	mov    0xf01123a8,%eax
f0100555:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010055c:	00 
f010055d:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100563:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100567:	89 04 24             	mov    %eax,(%esp)
f010056a:	e8 52 14 00 00       	call   f01019c1 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010056f:	8b 15 a8 23 11 f0    	mov    0xf01123a8,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100575:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010057a:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100580:	83 c0 01             	add    $0x1,%eax
f0100583:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100588:	75 f0                	jne    f010057a <cga_putc+0x12b>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010058a:	66 83 2d ac 23 11 f0 	subw   $0x50,0xf01123ac
f0100591:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100592:	8b 0d a4 23 11 f0    	mov    0xf01123a4,%ecx
f0100598:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059d:	89 ca                	mov    %ecx,%edx
f010059f:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005a0:	0f b7 1d ac 23 11 f0 	movzwl 0xf01123ac,%ebx
f01005a7:	8d 71 01             	lea    0x1(%ecx),%esi
f01005aa:	89 d8                	mov    %ebx,%eax
f01005ac:	66 c1 e8 08          	shr    $0x8,%ax
f01005b0:	89 f2                	mov    %esi,%edx
f01005b2:	ee                   	out    %al,(%dx)
f01005b3:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005b8:	89 ca                	mov    %ecx,%edx
f01005ba:	ee                   	out    %al,(%dx)
f01005bb:	89 d8                	mov    %ebx,%eax
f01005bd:	89 f2                	mov    %esi,%edx
f01005bf:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
	outb(addr_6845 + 1, crt_pos);
}
f01005c0:	83 c4 14             	add    $0x14,%esp
f01005c3:	5b                   	pop    %ebx
f01005c4:	5e                   	pop    %esi
f01005c5:	c3                   	ret    

f01005c6 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01005c6:	83 ec 1c             	sub    $0x1c,%esp
	cga_init();
f01005c9:	e8 e1 fc ff ff       	call   f01002af <cga_init>
	kbd_init();
	serial_init();
f01005ce:	e8 81 fc ff ff       	call   f0100254 <serial_init>

	if (!serial_exists)
f01005d3:	83 3d a0 23 11 f0 00 	cmpl   $0x0,0xf01123a0
f01005da:	75 0c                	jne    f01005e8 <cons_init+0x22>
		cprintf("Serial port does not exist!\n");
f01005dc:	c7 04 24 b9 1e 10 f0 	movl   $0xf0101eb9,(%esp)
f01005e3:	e8 32 08 00 00       	call   f0100e1a <cprintf>
}
f01005e8:	83 c4 1c             	add    $0x1c,%esp
f01005eb:	c3                   	ret    

f01005ec <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005ec:	83 ec 1c             	sub    $0x1c,%esp
	cons_putc(c);
f01005ef:	8b 44 24 20          	mov    0x20(%esp),%eax
f01005f3:	89 04 24             	mov    %eax,(%esp)
f01005f6:	e8 fa fd ff ff       	call   f01003f5 <cons_putc>
}
f01005fb:	83 c4 1c             	add    $0x1c,%esp
f01005fe:	c3                   	ret    

f01005ff <getchar>:

int
getchar(void)
{
f01005ff:	83 ec 0c             	sub    $0xc,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100602:	e8 ac fd ff ff       	call   f01003b3 <cons_getc>
f0100607:	85 c0                	test   %eax,%eax
f0100609:	74 f7                	je     f0100602 <getchar+0x3>
		/* do nothing */;
	return c;
}
f010060b:	83 c4 0c             	add    $0xc,%esp
f010060e:	c3                   	ret    

f010060f <iscons>:
int
iscons(int fdnum)
{
	// used by readline
	return 1;
}
f010060f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100614:	c3                   	ret    
	...

f0100620 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100620:	83 ec 1c             	sub    $0x1c,%esp
	extern char _start[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100623:	c7 04 24 f0 20 10 f0 	movl   $0xf01020f0,(%esp)
f010062a:	e8 eb 07 00 00       	call   f0100e1a <cprintf>
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
f010062f:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100636:	00 
f0100637:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f010063e:	f0 
f010063f:	c7 04 24 7c 21 10 f0 	movl   $0xf010217c,(%esp)
f0100646:	e8 cf 07 00 00       	call   f0100e1a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010064b:	c7 44 24 08 55 1e 10 	movl   $0x101e55,0x8(%esp)
f0100652:	00 
f0100653:	c7 44 24 04 55 1e 10 	movl   $0xf0101e55,0x4(%esp)
f010065a:	f0 
f010065b:	c7 04 24 a0 21 10 f0 	movl   $0xf01021a0,(%esp)
f0100662:	e8 b3 07 00 00       	call   f0100e1a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100667:	c7 44 24 08 70 23 11 	movl   $0x112370,0x8(%esp)
f010066e:	00 
f010066f:	c7 44 24 04 70 23 11 	movl   $0xf0112370,0x4(%esp)
f0100676:	f0 
f0100677:	c7 04 24 c4 21 10 f0 	movl   $0xf01021c4,(%esp)
f010067e:	e8 97 07 00 00       	call   f0100e1a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100683:	c7 44 24 08 10 2a 11 	movl   $0x112a10,0x8(%esp)
f010068a:	00 
f010068b:	c7 44 24 04 10 2a 11 	movl   $0xf0112a10,0x4(%esp)
f0100692:	f0 
f0100693:	c7 04 24 e8 21 10 f0 	movl   $0xf01021e8,(%esp)
f010069a:	e8 7b 07 00 00       	call   f0100e1a <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-_start+1023)/1024);
f010069f:	b8 0f 2e 11 f0       	mov    $0xf0112e0f,%eax
f01006a4:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006a9:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006af:	85 c0                	test   %eax,%eax
f01006b1:	0f 48 c2             	cmovs  %edx,%eax
f01006b4:	c1 f8 0a             	sar    $0xa,%eax
f01006b7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006bb:	c7 04 24 0c 22 10 f0 	movl   $0xf010220c,(%esp)
f01006c2:	e8 53 07 00 00       	call   f0100e1a <cprintf>
		(end-_start+1023)/1024);
	return 0;
}
f01006c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01006cc:	83 c4 1c             	add    $0x1c,%esp
f01006cf:	c3                   	ret    

f01006d0 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006d0:	83 ec 1c             	sub    $0x1c,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006d3:	c7 44 24 08 09 21 10 	movl   $0xf0102109,0x8(%esp)
f01006da:	f0 
f01006db:	c7 44 24 04 27 21 10 	movl   $0xf0102127,0x4(%esp)
f01006e2:	f0 
f01006e3:	c7 04 24 2c 21 10 f0 	movl   $0xf010212c,(%esp)
f01006ea:	e8 2b 07 00 00       	call   f0100e1a <cprintf>
f01006ef:	c7 44 24 08 38 22 10 	movl   $0xf0102238,0x8(%esp)
f01006f6:	f0 
f01006f7:	c7 44 24 04 35 21 10 	movl   $0xf0102135,0x4(%esp)
f01006fe:	f0 
f01006ff:	c7 04 24 2c 21 10 f0 	movl   $0xf010212c,(%esp)
f0100706:	e8 0f 07 00 00       	call   f0100e1a <cprintf>
	return 0;
}
f010070b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100710:	83 c4 1c             	add    $0x1c,%esp
f0100713:	c3                   	ret    

f0100714 <mon_backtrace>:
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	return 0;
}
f0100714:	b8 00 00 00 00       	mov    $0x0,%eax
f0100719:	c3                   	ret    

f010071a <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010071a:	57                   	push   %edi
f010071b:	56                   	push   %esi
f010071c:	53                   	push   %ebx
f010071d:	83 ec 50             	sub    $0x50,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100720:	c7 04 24 60 22 10 f0 	movl   $0xf0102260,(%esp)
f0100727:	e8 ee 06 00 00       	call   f0100e1a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010072c:	c7 04 24 84 22 10 f0 	movl   $0xf0102284,(%esp)
f0100733:	e8 e2 06 00 00       	call   f0100e1a <cprintf>
	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
f0100738:	8d 7c 24 10          	lea    0x10(%esp),%edi
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f010073c:	c7 04 24 3e 21 10 f0 	movl   $0xf010213e,(%esp)
f0100743:	e8 e8 0f 00 00       	call   f0101730 <readline>
f0100748:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010074a:	85 c0                	test   %eax,%eax
f010074c:	74 ee                	je     f010073c <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010074e:	c7 44 24 10 00 00 00 	movl   $0x0,0x10(%esp)
f0100755:	00 
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100756:	be 00 00 00 00       	mov    $0x0,%esi
f010075b:	eb 06                	jmp    f0100763 <monitor+0x49>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010075d:	c6 03 00             	movb   $0x0,(%ebx)
f0100760:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100763:	0f b6 03             	movzbl (%ebx),%eax
f0100766:	84 c0                	test   %al,%al
f0100768:	74 6a                	je     f01007d4 <monitor+0xba>
f010076a:	0f be c0             	movsbl %al,%eax
f010076d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100771:	c7 04 24 42 21 10 f0 	movl   $0xf0102142,(%esp)
f0100778:	e8 c3 11 00 00       	call   f0101940 <strchr>
f010077d:	85 c0                	test   %eax,%eax
f010077f:	75 dc                	jne    f010075d <monitor+0x43>
			*buf++ = 0;
		if (*buf == 0)
f0100781:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100784:	74 4e                	je     f01007d4 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100786:	83 fe 0f             	cmp    $0xf,%esi
f0100789:	75 16                	jne    f01007a1 <monitor+0x87>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010078b:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100792:	00 
f0100793:	c7 04 24 47 21 10 f0 	movl   $0xf0102147,(%esp)
f010079a:	e8 7b 06 00 00       	call   f0100e1a <cprintf>
f010079f:	eb 9b                	jmp    f010073c <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f01007a1:	89 5c b4 10          	mov    %ebx,0x10(%esp,%esi,4)
f01007a5:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01007a8:	0f b6 03             	movzbl (%ebx),%eax
f01007ab:	84 c0                	test   %al,%al
f01007ad:	75 0c                	jne    f01007bb <monitor+0xa1>
f01007af:	eb b2                	jmp    f0100763 <monitor+0x49>
			buf++;
f01007b1:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01007b4:	0f b6 03             	movzbl (%ebx),%eax
f01007b7:	84 c0                	test   %al,%al
f01007b9:	74 a8                	je     f0100763 <monitor+0x49>
f01007bb:	0f be c0             	movsbl %al,%eax
f01007be:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007c2:	c7 04 24 42 21 10 f0 	movl   $0xf0102142,(%esp)
f01007c9:	e8 72 11 00 00       	call   f0101940 <strchr>
f01007ce:	85 c0                	test   %eax,%eax
f01007d0:	74 df                	je     f01007b1 <monitor+0x97>
f01007d2:	eb 8f                	jmp    f0100763 <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f01007d4:	c7 44 b4 10 00 00 00 	movl   $0x0,0x10(%esp,%esi,4)
f01007db:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01007dc:	85 f6                	test   %esi,%esi
f01007de:	0f 84 58 ff ff ff    	je     f010073c <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01007e4:	c7 44 24 04 27 21 10 	movl   $0xf0102127,0x4(%esp)
f01007eb:	f0 
f01007ec:	8b 44 24 10          	mov    0x10(%esp),%eax
f01007f0:	89 04 24             	mov    %eax,(%esp)
f01007f3:	e8 d0 10 00 00       	call   f01018c8 <strcmp>
f01007f8:	ba 00 00 00 00       	mov    $0x0,%edx
f01007fd:	85 c0                	test   %eax,%eax
f01007ff:	74 1d                	je     f010081e <monitor+0x104>
f0100801:	c7 44 24 04 35 21 10 	movl   $0xf0102135,0x4(%esp)
f0100808:	f0 
f0100809:	8b 44 24 10          	mov    0x10(%esp),%eax
f010080d:	89 04 24             	mov    %eax,(%esp)
f0100810:	e8 b3 10 00 00       	call   f01018c8 <strcmp>
f0100815:	85 c0                	test   %eax,%eax
f0100817:	75 29                	jne    f0100842 <monitor+0x128>
f0100819:	ba 01 00 00 00       	mov    $0x1,%edx
			return commands[i].func(argc, argv, tf);
f010081e:	8d 04 12             	lea    (%edx,%edx,1),%eax
f0100821:	01 c2                	add    %eax,%edx
f0100823:	8b 44 24 60          	mov    0x60(%esp),%eax
f0100827:	89 44 24 08          	mov    %eax,0x8(%esp)
f010082b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010082f:	89 34 24             	mov    %esi,(%esp)
f0100832:	ff 14 95 b4 22 10 f0 	call   *-0xfefdd4c(,%edx,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100839:	85 c0                	test   %eax,%eax
f010083b:	78 1e                	js     f010085b <monitor+0x141>
f010083d:	e9 fa fe ff ff       	jmp    f010073c <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100842:	8b 44 24 10          	mov    0x10(%esp),%eax
f0100846:	89 44 24 04          	mov    %eax,0x4(%esp)
f010084a:	c7 04 24 64 21 10 f0 	movl   $0xf0102164,(%esp)
f0100851:	e8 c4 05 00 00       	call   f0100e1a <cprintf>
f0100856:	e9 e1 fe ff ff       	jmp    f010073c <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010085b:	83 c4 50             	add    $0x50,%esp
f010085e:	5b                   	pop    %ebx
f010085f:	5e                   	pop    %esi
f0100860:	5f                   	pop    %edi
f0100861:	c3                   	ret    

f0100862 <read_eip>:
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f0100862:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f0100865:	c3                   	ret    
	...

f0100868 <nvram_read>:
	sizeof(gdt) - 1, (unsigned long) gdt
};

static int
nvram_read(int r)
{
f0100868:	83 ec 1c             	sub    $0x1c,%esp
f010086b:	89 5c 24 14          	mov    %ebx,0x14(%esp)
f010086f:	89 74 24 18          	mov    %esi,0x18(%esp)
f0100873:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100875:	89 04 24             	mov    %eax,(%esp)
f0100878:	e8 2f 05 00 00       	call   f0100dac <mc146818_read>
f010087d:	89 c6                	mov    %eax,%esi
f010087f:	83 c3 01             	add    $0x1,%ebx
f0100882:	89 1c 24             	mov    %ebx,(%esp)
f0100885:	e8 22 05 00 00       	call   f0100dac <mc146818_read>
f010088a:	c1 e0 08             	shl    $0x8,%eax
f010088d:	09 f0                	or     %esi,%eax
}
f010088f:	8b 5c 24 14          	mov    0x14(%esp),%ebx
f0100893:	8b 74 24 18          	mov    0x18(%esp),%esi
f0100897:	83 c4 1c             	add    $0x1c,%esp
f010089a:	c3                   	ret    

f010089b <i386_detect_memory>:

void
i386_detect_memory(void)
{
f010089b:	83 ec 1c             	sub    $0x1c,%esp
	// CMOS tells us how many kilobytes there are
	basemem = ROUNDDOWN(nvram_read(NVRAM_BASELO)*1024, PGSIZE);
f010089e:	b8 15 00 00 00       	mov    $0x15,%eax
f01008a3:	e8 c0 ff ff ff       	call   f0100868 <nvram_read>
f01008a8:	c1 e0 0a             	shl    $0xa,%eax
f01008ab:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01008b0:	a3 c8 25 11 f0       	mov    %eax,0xf01125c8
	extmem = ROUNDDOWN(nvram_read(NVRAM_EXTLO)*1024, PGSIZE);
f01008b5:	b8 17 00 00 00       	mov    $0x17,%eax
f01008ba:	e8 a9 ff ff ff       	call   f0100868 <nvram_read>
f01008bf:	c1 e0 0a             	shl    $0xa,%eax
f01008c2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01008c7:	a3 cc 25 11 f0       	mov    %eax,0xf01125cc

	// Calculate the maximum physical address based on whether
	// or not there is any extended memory.  See comment in <inc/mmu.h>.
	if (extmem)
f01008cc:	85 c0                	test   %eax,%eax
f01008ce:	74 0c                	je     f01008dc <i386_detect_memory+0x41>
		maxpa = EXTPHYSMEM + extmem;
f01008d0:	05 00 00 10 00       	add    $0x100000,%eax
f01008d5:	a3 d0 25 11 f0       	mov    %eax,0xf01125d0
f01008da:	eb 0a                	jmp    f01008e6 <i386_detect_memory+0x4b>
	else
		maxpa = basemem;
f01008dc:	a1 c8 25 11 f0       	mov    0xf01125c8,%eax
f01008e1:	a3 d0 25 11 f0       	mov    %eax,0xf01125d0

	npage = maxpa / PGSIZE;
f01008e6:	a1 d0 25 11 f0       	mov    0xf01125d0,%eax
f01008eb:	89 c2                	mov    %eax,%edx
f01008ed:	c1 ea 0c             	shr    $0xc,%edx
f01008f0:	89 15 00 2a 11 f0    	mov    %edx,0xf0112a00

	cprintf("Physical memory: %dK available, ", (int)(maxpa/1024));
f01008f6:	c1 e8 0a             	shr    $0xa,%eax
f01008f9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008fd:	c7 04 24 c4 22 10 f0 	movl   $0xf01022c4,(%esp)
f0100904:	e8 11 05 00 00       	call   f0100e1a <cprintf>
	cprintf("base = %dK, extended = %dK\n", (int)(basemem/1024), (int)(extmem/1024));
f0100909:	a1 cc 25 11 f0       	mov    0xf01125cc,%eax
f010090e:	c1 e8 0a             	shr    $0xa,%eax
f0100911:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100915:	a1 c8 25 11 f0       	mov    0xf01125c8,%eax
f010091a:	c1 e8 0a             	shr    $0xa,%eax
f010091d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100921:	c7 04 24 15 23 10 f0 	movl   $0xf0102315,(%esp)
f0100928:	e8 ed 04 00 00       	call   f0100e1a <cprintf>
}
f010092d:	83 c4 1c             	add    $0x1c,%esp
f0100930:	c3                   	ret    

f0100931 <i386_vm_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read (or write). 
void
i386_vm_init(void)
{
f0100931:	83 ec 1c             	sub    $0x1c,%esp
	pde_t* pgdir;
	uint32_t cr0;
	size_t n;

	// Delete this line:
	panic("i386_vm_init: This function is not finished\n");
f0100934:	c7 44 24 08 e8 22 10 	movl   $0xf01022e8,0x8(%esp)
f010093b:	f0 
f010093c:	c7 44 24 04 94 00 00 	movl   $0x94,0x4(%esp)
f0100943:	00 
f0100944:	c7 04 24 31 23 10 f0 	movl   $0xf0102331,(%esp)
f010094b:	e8 46 f7 ff ff       	call   f0100096 <_panic>

f0100950 <page_init>:
// to allocate and deallocate physical memory via the page_free_list,
// and NEVER use boot_alloc()
//
void
page_init(void)
{
f0100950:	56                   	push   %esi
f0100951:	53                   	push   %ebx
	//     Some of it is in use, some is free. Where is the kernel?
	//     Which pages are used for page tables and other data structures?
	//
	// Change the code to reflect this.
	int i;
	LIST_INIT(&page_free_list);
f0100952:	c7 05 d4 25 11 f0 00 	movl   $0x0,0xf01125d4
f0100959:	00 00 00 
	for (i = 0; i < npage; i++) {
f010095c:	83 3d 00 2a 11 f0 00 	cmpl   $0x0,0xf0112a00
f0100963:	74 5f                	je     f01009c4 <page_init+0x74>
f0100965:	ba 00 00 00 00       	mov    $0x0,%edx
f010096a:	b8 00 00 00 00       	mov    $0x0,%eax
		pages[i].pp_ref = 0;
f010096f:	8d 34 52             	lea    (%edx,%edx,2),%esi
f0100972:	8d 14 b5 00 00 00 00 	lea    0x0(,%esi,4),%edx
f0100979:	8b 1d 0c 2a 11 f0    	mov    0xf0112a0c,%ebx
f010097f:	66 c7 44 13 08 00 00 	movw   $0x0,0x8(%ebx,%edx,1)
		LIST_INSERT_HEAD(&page_free_list, &pages[i], pp_link);
f0100986:	8b 0d d4 25 11 f0    	mov    0xf01125d4,%ecx
f010098c:	89 0c b3             	mov    %ecx,(%ebx,%esi,4)
f010098f:	85 c9                	test   %ecx,%ecx
f0100991:	74 11                	je     f01009a4 <page_init+0x54>
f0100993:	8b 1d 0c 2a 11 f0    	mov    0xf0112a0c,%ebx
f0100999:	01 d3                	add    %edx,%ebx
f010099b:	8b 0d d4 25 11 f0    	mov    0xf01125d4,%ecx
f01009a1:	89 59 04             	mov    %ebx,0x4(%ecx)
f01009a4:	03 15 0c 2a 11 f0    	add    0xf0112a0c,%edx
f01009aa:	89 15 d4 25 11 f0    	mov    %edx,0xf01125d4
f01009b0:	c7 42 04 d4 25 11 f0 	movl   $0xf01125d4,0x4(%edx)
	//     Which pages are used for page tables and other data structures?
	//
	// Change the code to reflect this.
	int i;
	LIST_INIT(&page_free_list);
	for (i = 0; i < npage; i++) {
f01009b7:	83 c0 01             	add    $0x1,%eax
f01009ba:	89 c2                	mov    %eax,%edx
f01009bc:	3b 05 00 2a 11 f0    	cmp    0xf0112a00,%eax
f01009c2:	72 ab                	jb     f010096f <page_init+0x1f>
		pages[i].pp_ref = 0;
		LIST_INSERT_HEAD(&page_free_list, &pages[i], pp_link);
	}
}
f01009c4:	5b                   	pop    %ebx
f01009c5:	5e                   	pop    %esi
f01009c6:	c3                   	ret    

f01009c7 <page_alloc>:
int
page_alloc(struct Page **pp_store)
{
	// Fill this function in
	return -E_NO_MEM;
}
f01009c7:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01009cc:	c3                   	ret    

f01009cd <page_free>:
//
void
page_free(struct Page *pp)
{
	// Fill this function in
}
f01009cd:	f3 c3                	repz ret 

f01009cf <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f01009cf:	8b 44 24 04          	mov    0x4(%esp),%eax
	if (--pp->pp_ref == 0)
f01009d3:	66 83 68 08 01       	subw   $0x1,0x8(%eax)
		page_free(pp);
}
f01009d8:	c3                   	ret    

f01009d9 <pgdir_walk>:
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
	// Fill this function in
	return NULL;
}
f01009d9:	b8 00 00 00 00       	mov    $0x0,%eax
f01009de:	c3                   	ret    

f01009df <page_insert>:
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm) 
{
	// Fill this function in
	return 0;
}
f01009df:	b8 00 00 00 00       	mov    $0x0,%eax
f01009e4:	c3                   	ret    

f01009e5 <page_lookup>:
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	return NULL;
}
f01009e5:	b8 00 00 00 00       	mov    $0x0,%eax
f01009ea:	c3                   	ret    

f01009eb <page_remove>:
//
void
page_remove(pde_t *pgdir, void *va)
{
	// Fill this function in
}
f01009eb:	f3 c3                	repz ret 

f01009ed <tlb_invalidate>:
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01009ed:	8b 44 24 08          	mov    0x8(%esp),%eax
f01009f1:	0f 01 38             	invlpg (%eax)
tlb_invalidate(pde_t *pgdir, void *va)
{
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01009f4:	c3                   	ret    
f01009f5:	00 00                	add    %al,(%eax)
	...

f01009f8 <envid2env>:
//   On success, sets *penv to the environment.
//   On error, sets *penv to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f01009f8:	53                   	push   %ebx
f01009f9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01009fd:	8b 4c 24 0c          	mov    0xc(%esp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0100a01:	85 c0                	test   %eax,%eax
f0100a03:	75 0e                	jne    f0100a13 <envid2env+0x1b>
		*env_store = curenv;
f0100a05:	a1 d8 25 11 f0       	mov    0xf01125d8,%eax
f0100a0a:	89 01                	mov    %eax,(%ecx)
		return 0;
f0100a0c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a11:	eb 55                	jmp    f0100a68 <envid2env+0x70>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0100a13:	89 c2                	mov    %eax,%edx
f0100a15:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a1b:	6b d2 64             	imul   $0x64,%edx,%edx
f0100a1e:	03 15 dc 25 11 f0    	add    0xf01125dc,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0100a24:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f0100a28:	74 05                	je     f0100a2f <envid2env+0x37>
f0100a2a:	39 42 4c             	cmp    %eax,0x4c(%edx)
f0100a2d:	74 0d                	je     f0100a3c <envid2env+0x44>
		*env_store = 0;
f0100a2f:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		return -E_BAD_ENV;
f0100a35:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0100a3a:	eb 2c                	jmp    f0100a68 <envid2env+0x70>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0100a3c:	83 7c 24 10 00       	cmpl   $0x0,0x10(%esp)
f0100a41:	74 1e                	je     f0100a61 <envid2env+0x69>
f0100a43:	a1 d8 25 11 f0       	mov    0xf01125d8,%eax
f0100a48:	39 c2                	cmp    %eax,%edx
f0100a4a:	74 15                	je     f0100a61 <envid2env+0x69>
f0100a4c:	8b 58 4c             	mov    0x4c(%eax),%ebx
f0100a4f:	39 5a 50             	cmp    %ebx,0x50(%edx)
f0100a52:	74 0d                	je     f0100a61 <envid2env+0x69>
		*env_store = 0;
f0100a54:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		return -E_BAD_ENV;
f0100a5a:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0100a5f:	eb 07                	jmp    f0100a68 <envid2env+0x70>
	}

	*env_store = e;
f0100a61:	89 11                	mov    %edx,(%ecx)
	return 0;
f0100a63:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100a68:	5b                   	pop    %ebx
f0100a69:	c3                   	ret    

f0100a6a <env_init>:
//
void
env_init(void)
{
	// LAB 3: Your code here.
}
f0100a6a:	f3 c3                	repz ret 

f0100a6c <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0100a6c:	53                   	push   %ebx
f0100a6d:	83 ec 28             	sub    $0x28,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = LIST_FIRST(&env_free_list)))
f0100a70:	8b 1d e0 25 11 f0    	mov    0xf01125e0,%ebx
f0100a76:	85 db                	test   %ebx,%ebx
f0100a78:	0f 84 fc 00 00 00    	je     f0100b7a <env_alloc+0x10e>
//
static int
env_setup_vm(struct Env *e)
{
	int i, r;
	struct Page *p = NULL;
f0100a7e:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
f0100a85:	00 

	// Allocate a page for the page directory
	if ((r = page_alloc(&p)) < 0)
f0100a86:	8d 44 24 1c          	lea    0x1c(%esp),%eax
f0100a8a:	89 04 24             	mov    %eax,(%esp)
f0100a8d:	e8 35 ff ff ff       	call   f01009c7 <page_alloc>
f0100a92:	85 c0                	test   %eax,%eax
f0100a94:	0f 88 e5 00 00 00    	js     f0100b7f <env_alloc+0x113>

	// LAB 3: Your code here.

	// VPT and UVPT map the env's own page table, with
	// different permissions.
	e->env_pgdir[PDX(VPT)]  = e->env_cr3 | PTE_P | PTE_W;
f0100a9a:	8b 43 5c             	mov    0x5c(%ebx),%eax
f0100a9d:	8b 53 60             	mov    0x60(%ebx),%edx
f0100aa0:	83 ca 03             	or     $0x3,%edx
f0100aa3:	89 90 fc 0e 00 00    	mov    %edx,0xefc(%eax)
	e->env_pgdir[PDX(UVPT)] = e->env_cr3 | PTE_P | PTE_U;
f0100aa9:	8b 43 5c             	mov    0x5c(%ebx),%eax
f0100aac:	8b 53 60             	mov    0x60(%ebx),%edx
f0100aaf:	83 ca 05             	or     $0x5,%edx
f0100ab2:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0100ab8:	8b 43 4c             	mov    0x4c(%ebx),%eax
f0100abb:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0100ac0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0100ac5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0100aca:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0100acd:	89 da                	mov    %ebx,%edx
f0100acf:	2b 15 dc 25 11 f0    	sub    0xf01125dc,%edx
f0100ad5:	c1 fa 02             	sar    $0x2,%edx
f0100ad8:	69 d2 29 5c 8f c2    	imul   $0xc28f5c29,%edx,%edx
f0100ade:	09 d0                	or     %edx,%eax
f0100ae0:	89 43 4c             	mov    %eax,0x4c(%ebx)
	
	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0100ae3:	8b 44 24 34          	mov    0x34(%esp),%eax
f0100ae7:	89 43 50             	mov    %eax,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0100aea:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
	e->env_runs = 0;
f0100af1:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0100af8:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0100aff:	00 
f0100b00:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100b07:	00 
f0100b08:	89 1c 24             	mov    %ebx,(%esp)
f0100b0b:	e8 8e 0e 00 00       	call   f010199e <memset>
	// Set up appropriate initial values for the segment registers.
	// GD_UD is the user data segment selector in the GDT, and 
	// GD_UT is the user text segment selector (see inc/memlayout.h).
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.
	e->env_tf.tf_ds = GD_UD | 3;
f0100b10:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0100b16:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0100b1c:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0100b22:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0100b29:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	LIST_REMOVE(e, env_link);
f0100b2f:	8b 43 44             	mov    0x44(%ebx),%eax
f0100b32:	85 c0                	test   %eax,%eax
f0100b34:	74 06                	je     f0100b3c <env_alloc+0xd0>
f0100b36:	8b 53 48             	mov    0x48(%ebx),%edx
f0100b39:	89 50 48             	mov    %edx,0x48(%eax)
f0100b3c:	8b 43 48             	mov    0x48(%ebx),%eax
f0100b3f:	8b 53 44             	mov    0x44(%ebx),%edx
f0100b42:	89 10                	mov    %edx,(%eax)
	*newenv_store = e;
f0100b44:	8b 44 24 30          	mov    0x30(%esp),%eax
f0100b48:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0100b4a:	8b 4b 4c             	mov    0x4c(%ebx),%ecx
f0100b4d:	8b 15 d8 25 11 f0    	mov    0xf01125d8,%edx
f0100b53:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b58:	85 d2                	test   %edx,%edx
f0100b5a:	74 03                	je     f0100b5f <env_alloc+0xf3>
f0100b5c:	8b 42 4c             	mov    0x4c(%edx),%eax
f0100b5f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100b63:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b67:	c7 04 24 3d 23 10 f0 	movl   $0xf010233d,(%esp)
f0100b6e:	e8 a7 02 00 00       	call   f0100e1a <cprintf>
	return 0;
f0100b73:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b78:	eb 05                	jmp    f0100b7f <env_alloc+0x113>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = LIST_FIRST(&env_free_list)))
		return -E_NO_FREE_ENV;
f0100b7a:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
	LIST_REMOVE(e, env_link);
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0100b7f:	83 c4 28             	add    $0x28,%esp
f0100b82:	5b                   	pop    %ebx
f0100b83:	c3                   	ret    

f0100b84 <env_create>:
// environment there. 
void
env_create(uint8_t *binary, size_t size)
{
	// LAB 3: Your code here.
}
f0100b84:	f3 c3                	repz ret 

f0100b86 <env_free>:
//
// Frees env e and all memory it uses.
// 
void
env_free(struct Env *e)
{
f0100b86:	55                   	push   %ebp
f0100b87:	57                   	push   %edi
f0100b88:	56                   	push   %esi
f0100b89:	53                   	push   %ebx
f0100b8a:	83 ec 2c             	sub    $0x2c,%esp
f0100b8d:	8b 7c 24 40          	mov    0x40(%esp),%edi
	physaddr_t pa;
	
	// If freeing the current environment, switch to boot_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0100b91:	a1 d8 25 11 f0       	mov    0xf01125d8,%eax
f0100b96:	39 c7                	cmp    %eax,%edi
f0100b98:	75 09                	jne    f0100ba3 <env_free+0x1d>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0100b9a:	8b 15 04 2a 11 f0    	mov    0xf0112a04,%edx
f0100ba0:	0f 22 da             	mov    %edx,%cr3
		lcr3(boot_cr3);

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0100ba3:	8b 4f 4c             	mov    0x4c(%edi),%ecx
f0100ba6:	ba 00 00 00 00       	mov    $0x0,%edx
f0100bab:	85 c0                	test   %eax,%eax
f0100bad:	74 03                	je     f0100bb2 <env_free+0x2c>
f0100baf:	8b 50 4c             	mov    0x4c(%eax),%edx
f0100bb2:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100bb6:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100bba:	c7 04 24 52 23 10 f0 	movl   $0xf0102352,(%esp)
f0100bc1:	e8 54 02 00 00       	call   f0100e1a <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0100bc6:	c7 44 24 14 00 00 00 	movl   $0x0,0x14(%esp)
f0100bcd:	00 

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0100bce:	8b 44 24 14          	mov    0x14(%esp),%eax
f0100bd2:	c1 e0 02             	shl    $0x2,%eax
f0100bd5:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f0100bd9:	8b 47 5c             	mov    0x5c(%edi),%eax
f0100bdc:	8b 54 24 14          	mov    0x14(%esp),%edx
f0100be0:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0100be3:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0100be9:	0f 84 bc 00 00 00    	je     f0100cab <env_free+0x125>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0100bef:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
		pt = (pte_t*) KADDR(pa);
f0100bf5:	89 f0                	mov    %esi,%eax
f0100bf7:	c1 e8 0c             	shr    $0xc,%eax
f0100bfa:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100bfe:	3b 05 00 2a 11 f0    	cmp    0xf0112a00,%eax
f0100c04:	72 20                	jb     f0100c26 <env_free+0xa0>
f0100c06:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100c0a:	c7 44 24 08 ac 23 10 	movl   $0xf01023ac,0x8(%esp)
f0100c11:	f0 
f0100c12:	c7 44 24 04 32 01 00 	movl   $0x132,0x4(%esp)
f0100c19:	00 
f0100c1a:	c7 04 24 68 23 10 f0 	movl   $0xf0102368,(%esp)
f0100c21:	e8 70 f4 ff ff       	call   f0100096 <_panic>

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0100c26:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f0100c2a:	c1 e5 16             	shl    $0x16,%ebp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0100c2d:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0100c32:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0100c39:	01 
f0100c3a:	74 16                	je     f0100c52 <env_free+0xcc>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0100c3c:	89 d8                	mov    %ebx,%eax
f0100c3e:	c1 e0 0c             	shl    $0xc,%eax
f0100c41:	09 e8                	or     %ebp,%eax
f0100c43:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c47:	8b 47 5c             	mov    0x5c(%edi),%eax
f0100c4a:	89 04 24             	mov    %eax,(%esp)
f0100c4d:	e8 99 fd ff ff       	call   f01009eb <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0100c52:	83 c3 01             	add    $0x1,%ebx
f0100c55:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0100c5b:	75 d5                	jne    f0100c32 <env_free+0xac>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0100c5d:	8b 47 5c             	mov    0x5c(%edi),%eax
f0100c60:	8b 54 24 1c          	mov    0x1c(%esp),%edx
f0100c64:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PPN(pa) >= npage)
f0100c6b:	8b 44 24 18          	mov    0x18(%esp),%eax
f0100c6f:	3b 05 00 2a 11 f0    	cmp    0xf0112a00,%eax
f0100c75:	72 1c                	jb     f0100c93 <env_free+0x10d>
		panic("pa2page called with invalid pa");
f0100c77:	c7 44 24 08 d0 23 10 	movl   $0xf01023d0,0x8(%esp)
f0100c7e:	f0 
f0100c7f:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0100c86:	00 
f0100c87:	c7 04 24 73 23 10 f0 	movl   $0xf0102373,(%esp)
f0100c8e:	e8 03 f4 ff ff       	call   f0100096 <_panic>
	return &pages[PPN(pa)];
f0100c93:	8b 54 24 18          	mov    0x18(%esp),%edx
f0100c97:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100c9a:	c1 e0 02             	shl    $0x2,%eax
f0100c9d:	03 05 0c 2a 11 f0    	add    0xf0112a0c,%eax
		page_decref(pa2page(pa));
f0100ca3:	89 04 24             	mov    %eax,(%esp)
f0100ca6:	e8 24 fd ff ff       	call   f01009cf <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0100cab:	83 44 24 14 01       	addl   $0x1,0x14(%esp)
f0100cb0:	81 7c 24 14 bb 03 00 	cmpl   $0x3bb,0x14(%esp)
f0100cb7:	00 
f0100cb8:	0f 85 10 ff ff ff    	jne    f0100bce <env_free+0x48>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = e->env_cr3;
f0100cbe:	8b 47 60             	mov    0x60(%edi),%eax
	e->env_pgdir = 0;
f0100cc1:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	e->env_cr3 = 0;
f0100cc8:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PPN(pa) >= npage)
f0100ccf:	c1 e8 0c             	shr    $0xc,%eax
f0100cd2:	3b 05 00 2a 11 f0    	cmp    0xf0112a00,%eax
f0100cd8:	72 1c                	jb     f0100cf6 <env_free+0x170>
		panic("pa2page called with invalid pa");
f0100cda:	c7 44 24 08 d0 23 10 	movl   $0xf01023d0,0x8(%esp)
f0100ce1:	f0 
f0100ce2:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0100ce9:	00 
f0100cea:	c7 04 24 73 23 10 f0 	movl   $0xf0102373,(%esp)
f0100cf1:	e8 a0 f3 ff ff       	call   f0100096 <_panic>
	return &pages[PPN(pa)];
f0100cf6:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100cf9:	c1 e0 02             	shl    $0x2,%eax
f0100cfc:	03 05 0c 2a 11 f0    	add    0xf0112a0c,%eax
	page_decref(pa2page(pa));
f0100d02:	89 04 24             	mov    %eax,(%esp)
f0100d05:	e8 c5 fc ff ff       	call   f01009cf <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0100d0a:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	LIST_INSERT_HEAD(&env_free_list, e, env_link);
f0100d11:	a1 e0 25 11 f0       	mov    0xf01125e0,%eax
f0100d16:	89 47 44             	mov    %eax,0x44(%edi)
f0100d19:	85 c0                	test   %eax,%eax
f0100d1b:	74 06                	je     f0100d23 <env_free+0x19d>
f0100d1d:	8d 57 44             	lea    0x44(%edi),%edx
f0100d20:	89 50 48             	mov    %edx,0x48(%eax)
f0100d23:	89 3d e0 25 11 f0    	mov    %edi,0xf01125e0
f0100d29:	c7 47 48 e0 25 11 f0 	movl   $0xf01125e0,0x48(%edi)
}
f0100d30:	83 c4 2c             	add    $0x2c,%esp
f0100d33:	5b                   	pop    %ebx
f0100d34:	5e                   	pop    %esi
f0100d35:	5f                   	pop    %edi
f0100d36:	5d                   	pop    %ebp
f0100d37:	c3                   	ret    

f0100d38 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e) 
{
f0100d38:	83 ec 1c             	sub    $0x1c,%esp
	env_free(e);
f0100d3b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0100d3f:	89 04 24             	mov    %eax,(%esp)
f0100d42:	e8 3f fe ff ff       	call   f0100b86 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0100d47:	c7 04 24 f0 23 10 f0 	movl   $0xf01023f0,(%esp)
f0100d4e:	e8 c7 00 00 00       	call   f0100e1a <cprintf>
	while (1)
		monitor(NULL);
f0100d53:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100d5a:	e8 bb f9 ff ff       	call   f010071a <monitor>
f0100d5f:	eb f2                	jmp    f0100d53 <env_destroy+0x1b>

f0100d61 <env_pop_tf>:
// This exits the kernel and starts executing some environment's code.
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0100d61:	83 ec 1c             	sub    $0x1c,%esp
	__asm __volatile("movl %0,%%esp\n"
f0100d64:	8b 64 24 20          	mov    0x20(%esp),%esp
f0100d68:	61                   	popa   
f0100d69:	07                   	pop    %es
f0100d6a:	1f                   	pop    %ds
f0100d6b:	83 c4 08             	add    $0x8,%esp
f0100d6e:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0100d6f:	c7 44 24 08 81 23 10 	movl   $0xf0102381,0x8(%esp)
f0100d76:	f0 
f0100d77:	c7 44 24 04 69 01 00 	movl   $0x169,0x4(%esp)
f0100d7e:	00 
f0100d7f:	c7 04 24 68 23 10 f0 	movl   $0xf0102368,(%esp)
f0100d86:	e8 0b f3 ff ff       	call   f0100096 <_panic>

f0100d8b <env_run>:
// Note: if this is the first call to env_run, curenv is NULL.
//  (This function does not return.)
//
void
env_run(struct Env *e)
{
f0100d8b:	83 ec 1c             	sub    $0x1c,%esp
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.
	
	// LAB 3: Your code here.

        panic("env_run not yet implemented");
f0100d8e:	c7 44 24 08 8d 23 10 	movl   $0xf010238d,0x8(%esp)
f0100d95:	f0 
f0100d96:	c7 44 24 04 83 01 00 	movl   $0x183,0x4(%esp)
f0100d9d:	00 
f0100d9e:	c7 04 24 68 23 10 f0 	movl   $0xf0102368,(%esp)
f0100da5:	e8 ec f2 ff ff       	call   f0100096 <_panic>
	...

f0100dac <mc146818_read>:
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100dac:	ba 70 00 00 00       	mov    $0x70,%edx
f0100db1:	8b 44 24 04          	mov    0x4(%esp),%eax
f0100db5:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100db6:	b2 71                	mov    $0x71,%dl
f0100db8:	ec                   	in     (%dx),%al

unsigned
mc146818_read(unsigned reg)
{
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0100db9:	0f b6 c0             	movzbl %al,%eax
}
f0100dbc:	c3                   	ret    

f0100dbd <mc146818_write>:
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100dbd:	ba 70 00 00 00       	mov    $0x70,%edx
f0100dc2:	8b 44 24 04          	mov    0x4(%esp),%eax
f0100dc6:	ee                   	out    %al,(%dx)
f0100dc7:	b2 71                	mov    $0x71,%dl
f0100dc9:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100dcd:	ee                   	out    %al,(%dx)
void
mc146818_write(unsigned reg, unsigned datum)
{
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0100dce:	c3                   	ret    
	...

f0100dd0 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100dd0:	83 ec 1c             	sub    $0x1c,%esp
	cputchar(ch);
f0100dd3:	8b 44 24 20          	mov    0x20(%esp),%eax
f0100dd7:	89 04 24             	mov    %eax,(%esp)
f0100dda:	e8 0d f8 ff ff       	call   f01005ec <cputchar>
	*cnt++;
}
f0100ddf:	83 c4 1c             	add    $0x1c,%esp
f0100de2:	c3                   	ret    

f0100de3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100de3:	83 ec 2c             	sub    $0x2c,%esp
	int cnt = 0;
f0100de6:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
f0100ded:	00 

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100dee:	8b 44 24 34          	mov    0x34(%esp),%eax
f0100df2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100df6:	8b 44 24 30          	mov    0x30(%esp),%eax
f0100dfa:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100dfe:	8d 44 24 1c          	lea    0x1c(%esp),%eax
f0100e02:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e06:	c7 04 24 d0 0d 10 f0 	movl   $0xf0100dd0,(%esp)
f0100e0d:	e8 55 04 00 00       	call   f0101267 <vprintfmt>
	return cnt;
}
f0100e12:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0100e16:	83 c4 2c             	add    $0x2c,%esp
f0100e19:	c3                   	ret    

f0100e1a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100e1a:	83 ec 1c             	sub    $0x1c,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
	cnt = vcprintf(fmt, ap);
f0100e1d:	8d 44 24 24          	lea    0x24(%esp),%eax
f0100e21:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e25:	8b 44 24 20          	mov    0x20(%esp),%eax
f0100e29:	89 04 24             	mov    %eax,(%esp)
f0100e2c:	e8 b2 ff ff ff       	call   f0100de3 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100e31:	83 c4 1c             	add    $0x1c,%esp
f0100e34:	c3                   	ret    
f0100e35:	00 00                	add    %al,(%eax)
	...

f0100e38 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100e38:	55                   	push   %ebp
f0100e39:	57                   	push   %edi
f0100e3a:	56                   	push   %esi
f0100e3b:	53                   	push   %ebx
f0100e3c:	83 ec 0c             	sub    $0xc,%esp
f0100e3f:	89 c3                	mov    %eax,%ebx
f0100e41:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100e45:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100e49:	8b 74 24 20          	mov    0x20(%esp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100e4d:	8b 0a                	mov    (%edx),%ecx
f0100e4f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100e53:	8b 38                	mov    (%eax),%edi
f0100e55:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
	
	while (l <= r) {
f0100e5c:	eb 79                	jmp    f0100ed7 <stab_binsearch+0x9f>
		int true_m = (l + r) / 2, m = true_m;
f0100e5e:	8d 04 39             	lea    (%ecx,%edi,1),%eax
f0100e61:	bd 02 00 00 00       	mov    $0x2,%ebp
f0100e66:	99                   	cltd   
f0100e67:	f7 fd                	idiv   %ebp
f0100e69:	89 c2                	mov    %eax,%edx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100e6b:	eb 01                	jmp    f0100e6e <stab_binsearch+0x36>
			m--;
f0100e6d:	4a                   	dec    %edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100e6e:	39 ca                	cmp    %ecx,%edx
f0100e70:	7c 1e                	jl     f0100e90 <stab_binsearch+0x58>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100e72:	6b ea 0c             	imul   $0xc,%edx,%ebp
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100e75:	0f b6 6c 2b 04       	movzbl 0x4(%ebx,%ebp,1),%ebp
f0100e7a:	39 f5                	cmp    %esi,%ebp
f0100e7c:	75 ef                	jne    f0100e6d <stab_binsearch+0x35>
f0100e7e:	89 14 24             	mov    %edx,(%esp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100e81:	6b ea 0c             	imul   $0xc,%edx,%ebp
f0100e84:	8b 6c 2b 08          	mov    0x8(%ebx,%ebp,1),%ebp
f0100e88:	3b 6c 24 24          	cmp    0x24(%esp),%ebp
f0100e8c:	73 19                	jae    f0100ea7 <stab_binsearch+0x6f>
f0100e8e:	eb 05                	jmp    f0100e95 <stab_binsearch+0x5d>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100e90:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0100e93:	eb 42                	jmp    f0100ed7 <stab_binsearch+0x9f>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100e95:	8b 4c 24 04          	mov    0x4(%esp),%ecx
f0100e99:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0100e9b:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100e9e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100ea5:	eb 30                	jmp    f0100ed7 <stab_binsearch+0x9f>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100ea7:	3b 6c 24 24          	cmp    0x24(%esp),%ebp
f0100eab:	76 14                	jbe    f0100ec1 <stab_binsearch+0x89>
			*region_right = m - 1;
f0100ead:	8b 3c 24             	mov    (%esp),%edi
f0100eb0:	4f                   	dec    %edi
f0100eb1:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0100eb5:	89 7d 00             	mov    %edi,0x0(%ebp)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100eb8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100ebf:	eb 16                	jmp    f0100ed7 <stab_binsearch+0x9f>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100ec1:	8b 0c 24             	mov    (%esp),%ecx
f0100ec4:	8b 44 24 04          	mov    0x4(%esp),%eax
f0100ec8:	89 08                	mov    %ecx,(%eax)
			l = m;
			addr++;
f0100eca:	ff 44 24 24          	incl   0x24(%esp)
f0100ece:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100ed0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100ed7:	39 f9                	cmp    %edi,%ecx
f0100ed9:	7e 83                	jle    f0100e5e <stab_binsearch+0x26>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100edb:	83 3c 24 00          	cmpl   $0x0,(%esp)
f0100edf:	75 0f                	jne    f0100ef0 <stab_binsearch+0xb8>
		*region_right = *region_left - 1;
f0100ee1:	8b 54 24 04          	mov    0x4(%esp),%edx
f0100ee5:	8b 02                	mov    (%edx),%eax
f0100ee7:	48                   	dec    %eax
f0100ee8:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0100eec:	89 01                	mov    %eax,(%ecx)
f0100eee:	eb 25                	jmp    f0100f15 <stab_binsearch+0xdd>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ef0:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0100ef4:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100ef6:	8b 54 24 04          	mov    0x4(%esp),%edx
f0100efa:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100efc:	eb 01                	jmp    f0100eff <stab_binsearch+0xc7>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100efe:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100eff:	39 c1                	cmp    %eax,%ecx
f0100f01:	7d 0c                	jge    f0100f0f <stab_binsearch+0xd7>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100f03:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100f06:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0100f0b:	39 f2                	cmp    %esi,%edx
f0100f0d:	75 ef                	jne    f0100efe <stab_binsearch+0xc6>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100f0f:	8b 54 24 04          	mov    0x4(%esp),%edx
f0100f13:	89 02                	mov    %eax,(%edx)
	}
}
f0100f15:	83 c4 0c             	add    $0xc,%esp
f0100f18:	5b                   	pop    %ebx
f0100f19:	5e                   	pop    %esi
f0100f1a:	5f                   	pop    %edi
f0100f1b:	5d                   	pop    %ebp
f0100f1c:	c3                   	ret    

f0100f1d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100f1d:	83 ec 2c             	sub    $0x2c,%esp
f0100f20:	89 5c 24 20          	mov    %ebx,0x20(%esp)
f0100f24:	89 74 24 24          	mov    %esi,0x24(%esp)
f0100f28:	89 7c 24 28          	mov    %edi,0x28(%esp)
f0100f2c:	8b 74 24 30          	mov    0x30(%esp),%esi
f0100f30:	8b 5c 24 34          	mov    0x34(%esp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100f34:	c7 03 28 24 10 f0    	movl   $0xf0102428,(%ebx)
	info->eip_line = 0;
f0100f3a:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100f41:	c7 43 08 28 24 10 f0 	movl   $0xf0102428,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100f48:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100f4f:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100f52:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100f59:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100f5f:	76 12                	jbe    f0100f73 <debuginfo_eip+0x56>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100f61:	b8 28 93 10 f0       	mov    $0xf0109328,%eax
f0100f66:	3d f1 6e 10 f0       	cmp    $0xf0106ef1,%eax
f0100f6b:	0f 86 7a 01 00 00    	jbe    f01010eb <debuginfo_eip+0x1ce>
f0100f71:	eb 1c                	jmp    f0100f8f <debuginfo_eip+0x72>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100f73:	c7 44 24 08 32 24 10 	movl   $0xf0102432,0x8(%esp)
f0100f7a:	f0 
f0100f7b:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
f0100f82:	00 
f0100f83:	c7 04 24 3f 24 10 f0 	movl   $0xf010243f,(%esp)
f0100f8a:	e8 07 f1 ff ff       	call   f0100096 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100f8f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100f94:	80 3d 27 93 10 f0 00 	cmpb   $0x0,0xf0109327
f0100f9b:	0f 85 56 01 00 00    	jne    f01010f7 <debuginfo_eip+0x1da>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100fa1:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
f0100fa8:	00 
	rfile = (stab_end - stabs) - 1;
f0100fa9:	b8 f0 6e 10 f0       	mov    $0xf0106ef0,%eax
f0100fae:	2d 60 26 10 f0       	sub    $0xf0102660,%eax
f0100fb3:	c1 f8 02             	sar    $0x2,%eax
f0100fb6:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100fbc:	83 e8 01             	sub    $0x1,%eax
f0100fbf:	89 44 24 18          	mov    %eax,0x18(%esp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100fc3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100fc7:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100fce:	8d 4c 24 18          	lea    0x18(%esp),%ecx
f0100fd2:	8d 54 24 1c          	lea    0x1c(%esp),%edx
f0100fd6:	b8 60 26 10 f0       	mov    $0xf0102660,%eax
f0100fdb:	e8 58 fe ff ff       	call   f0100e38 <stab_binsearch>
	if (lfile == 0)
f0100fe0:	8b 54 24 1c          	mov    0x1c(%esp),%edx
		return -1;
f0100fe4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100fe9:	85 d2                	test   %edx,%edx
f0100feb:	0f 84 06 01 00 00    	je     f01010f7 <debuginfo_eip+0x1da>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100ff1:	89 54 24 14          	mov    %edx,0x14(%esp)
	rfun = rfile;
f0100ff5:	8b 44 24 18          	mov    0x18(%esp),%eax
f0100ff9:	89 44 24 10          	mov    %eax,0x10(%esp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100ffd:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101001:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0101008:	8d 4c 24 10          	lea    0x10(%esp),%ecx
f010100c:	8d 54 24 14          	lea    0x14(%esp),%edx
f0101010:	b8 60 26 10 f0       	mov    $0xf0102660,%eax
f0101015:	e8 1e fe ff ff       	call   f0100e38 <stab_binsearch>

	if (lfun <= rfun) {
f010101a:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010101e:	3b 7c 24 10          	cmp    0x10(%esp),%edi
f0101022:	7f 2e                	jg     f0101052 <debuginfo_eip+0x135>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0101024:	6b c7 0c             	imul   $0xc,%edi,%eax
f0101027:	8d 90 60 26 10 f0    	lea    -0xfefd9a0(%eax),%edx
f010102d:	8b 80 60 26 10 f0    	mov    -0xfefd9a0(%eax),%eax
f0101033:	b9 28 93 10 f0       	mov    $0xf0109328,%ecx
f0101038:	81 e9 f1 6e 10 f0    	sub    $0xf0106ef1,%ecx
f010103e:	39 c8                	cmp    %ecx,%eax
f0101040:	73 08                	jae    f010104a <debuginfo_eip+0x12d>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0101042:	05 f1 6e 10 f0       	add    $0xf0106ef1,%eax
f0101047:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010104a:	8b 42 08             	mov    0x8(%edx),%eax
f010104d:	89 43 10             	mov    %eax,0x10(%ebx)
f0101050:	eb 07                	jmp    f0101059 <debuginfo_eip+0x13c>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0101052:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0101055:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0101059:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0101060:	00 
f0101061:	8b 43 08             	mov    0x8(%ebx),%eax
f0101064:	89 04 24             	mov    %eax,(%esp)
f0101067:	e8 06 09 00 00       	call   f0101972 <strfind>
f010106c:	2b 43 08             	sub    0x8(%ebx),%eax
f010106f:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101072:	8b 54 24 1c          	mov    0x1c(%esp),%edx
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	// Your code here.

	
	return 0;
f0101076:	b8 00 00 00 00       	mov    $0x0,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010107b:	39 d7                	cmp    %edx,%edi
f010107d:	7c 78                	jl     f01010f7 <debuginfo_eip+0x1da>
	       && stabs[lline].n_type != N_SOL
f010107f:	89 f8                	mov    %edi,%eax
f0101081:	6b cf 0c             	imul   $0xc,%edi,%ecx
f0101084:	80 b9 64 26 10 f0 84 	cmpb   $0x84,-0xfefd99c(%ecx)
f010108b:	75 18                	jne    f01010a5 <debuginfo_eip+0x188>
f010108d:	eb 35                	jmp    f01010c4 <debuginfo_eip+0x1a7>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f010108f:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101092:	39 d7                	cmp    %edx,%edi
f0101094:	7c 5c                	jl     f01010f2 <debuginfo_eip+0x1d5>
	       && stabs[lline].n_type != N_SOL
f0101096:	89 f8                	mov    %edi,%eax
f0101098:	8d 0c 7f             	lea    (%edi,%edi,2),%ecx
f010109b:	80 3c 8d 64 26 10 f0 	cmpb   $0x84,-0xfefd99c(,%ecx,4)
f01010a2:	84 
f01010a3:	74 1f                	je     f01010c4 <debuginfo_eip+0x1a7>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01010a5:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01010a8:	8d 04 85 60 26 10 f0 	lea    -0xfefd9a0(,%eax,4),%eax
f01010af:	80 78 04 64          	cmpb   $0x64,0x4(%eax)
f01010b3:	75 da                	jne    f010108f <debuginfo_eip+0x172>
f01010b5:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01010b9:	74 d4                	je     f010108f <debuginfo_eip+0x172>
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	// Your code here.

	
	return 0;
f01010bb:	b8 00 00 00 00       	mov    $0x0,%eax
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01010c0:	39 d7                	cmp    %edx,%edi
f01010c2:	7c 33                	jl     f01010f7 <debuginfo_eip+0x1da>
f01010c4:	6b ff 0c             	imul   $0xc,%edi,%edi
f01010c7:	8b 97 60 26 10 f0    	mov    -0xfefd9a0(%edi),%edx
f01010cd:	b9 28 93 10 f0       	mov    $0xf0109328,%ecx
f01010d2:	81 e9 f1 6e 10 f0    	sub    $0xf0106ef1,%ecx
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	// Your code here.

	
	return 0;
f01010d8:	b8 00 00 00 00       	mov    $0x0,%eax
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01010dd:	39 ca                	cmp    %ecx,%edx
f01010df:	73 16                	jae    f01010f7 <debuginfo_eip+0x1da>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01010e1:	81 c2 f1 6e 10 f0    	add    $0xf0106ef1,%edx
f01010e7:	89 13                	mov    %edx,(%ebx)
f01010e9:	eb 0c                	jmp    f01010f7 <debuginfo_eip+0x1da>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01010eb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01010f0:	eb 05                	jmp    f01010f7 <debuginfo_eip+0x1da>
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	// Your code here.

	
	return 0;
f01010f2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01010f7:	8b 5c 24 20          	mov    0x20(%esp),%ebx
f01010fb:	8b 74 24 24          	mov    0x24(%esp),%esi
f01010ff:	8b 7c 24 28          	mov    0x28(%esp),%edi
f0101103:	83 c4 2c             	add    $0x2c,%esp
f0101106:	c3                   	ret    
	...

f0101108 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101108:	55                   	push   %ebp
f0101109:	57                   	push   %edi
f010110a:	56                   	push   %esi
f010110b:	53                   	push   %ebx
f010110c:	83 ec 3c             	sub    $0x3c,%esp
f010110f:	89 c5                	mov    %eax,%ebp
f0101111:	89 d7                	mov    %edx,%edi
f0101113:	8b 44 24 50          	mov    0x50(%esp),%eax
f0101117:	89 44 24 2c          	mov    %eax,0x2c(%esp)
f010111b:	8b 44 24 54          	mov    0x54(%esp),%eax
f010111f:	89 44 24 28          	mov    %eax,0x28(%esp)
f0101123:	8b 5c 24 5c          	mov    0x5c(%esp),%ebx
f0101127:	8b 74 24 60          	mov    0x60(%esp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010112b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101130:	3b 44 24 28          	cmp    0x28(%esp),%eax
f0101134:	72 13                	jb     f0101149 <printnum+0x41>
f0101136:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f010113a:	39 44 24 58          	cmp    %eax,0x58(%esp)
f010113e:	76 09                	jbe    f0101149 <printnum+0x41>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0101140:	83 eb 01             	sub    $0x1,%ebx
f0101143:	85 db                	test   %ebx,%ebx
f0101145:	7f 53                	jg     f010119a <printnum+0x92>
f0101147:	eb 5f                	jmp    f01011a8 <printnum+0xa0>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0101149:	89 74 24 10          	mov    %esi,0x10(%esp)
f010114d:	83 eb 01             	sub    $0x1,%ebx
f0101150:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101154:	8b 44 24 58          	mov    0x58(%esp),%eax
f0101158:	89 44 24 08          	mov    %eax,0x8(%esp)
f010115c:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0101160:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0101164:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010116b:	00 
f010116c:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f0101170:	89 04 24             	mov    %eax,(%esp)
f0101173:	8b 44 24 28          	mov    0x28(%esp),%eax
f0101177:	89 44 24 04          	mov    %eax,0x4(%esp)
f010117b:	e8 30 0a 00 00       	call   f0101bb0 <__udivdi3>
f0101180:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101184:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101188:	89 04 24             	mov    %eax,(%esp)
f010118b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010118f:	89 fa                	mov    %edi,%edx
f0101191:	89 e8                	mov    %ebp,%eax
f0101193:	e8 70 ff ff ff       	call   f0101108 <printnum>
f0101198:	eb 0e                	jmp    f01011a8 <printnum+0xa0>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010119a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010119e:	89 34 24             	mov    %esi,(%esp)
f01011a1:	ff d5                	call   *%ebp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01011a3:	83 eb 01             	sub    $0x1,%ebx
f01011a6:	75 f2                	jne    f010119a <printnum+0x92>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01011a8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011ac:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01011b0:	8b 44 24 58          	mov    0x58(%esp),%eax
f01011b4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011b8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01011bf:	00 
f01011c0:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f01011c4:	89 04 24             	mov    %eax,(%esp)
f01011c7:	8b 44 24 28          	mov    0x28(%esp),%eax
f01011cb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011cf:	e8 0c 0b 00 00       	call   f0101ce0 <__umoddi3>
f01011d4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011d8:	0f be 80 4d 24 10 f0 	movsbl -0xfefdbb3(%eax),%eax
f01011df:	89 04 24             	mov    %eax,(%esp)
f01011e2:	ff d5                	call   *%ebp
}
f01011e4:	83 c4 3c             	add    $0x3c,%esp
f01011e7:	5b                   	pop    %ebx
f01011e8:	5e                   	pop    %esi
f01011e9:	5f                   	pop    %edi
f01011ea:	5d                   	pop    %ebp
f01011eb:	c3                   	ret    

f01011ec <getuint>:
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01011ec:	83 fa 01             	cmp    $0x1,%edx
f01011ef:	7e 0d                	jle    f01011fe <getuint+0x12>
		return va_arg(*ap, unsigned long long);
f01011f1:	8b 10                	mov    (%eax),%edx
f01011f3:	8d 4a 08             	lea    0x8(%edx),%ecx
f01011f6:	89 08                	mov    %ecx,(%eax)
f01011f8:	8b 02                	mov    (%edx),%eax
f01011fa:	8b 52 04             	mov    0x4(%edx),%edx
f01011fd:	c3                   	ret    
	else if (lflag)
f01011fe:	85 d2                	test   %edx,%edx
f0101200:	74 0f                	je     f0101211 <getuint+0x25>
		return va_arg(*ap, unsigned long);
f0101202:	8b 10                	mov    (%eax),%edx
f0101204:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101207:	89 08                	mov    %ecx,(%eax)
f0101209:	8b 02                	mov    (%edx),%eax
f010120b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101210:	c3                   	ret    
	else
		return va_arg(*ap, unsigned int);
f0101211:	8b 10                	mov    (%eax),%edx
f0101213:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101216:	89 08                	mov    %ecx,(%eax)
f0101218:	8b 02                	mov    (%edx),%eax
f010121a:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010121f:	c3                   	ret    

f0101220 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101220:	8b 44 24 08          	mov    0x8(%esp),%eax
	b->cnt++;
f0101224:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0101228:	8b 10                	mov    (%eax),%edx
f010122a:	3b 50 04             	cmp    0x4(%eax),%edx
f010122d:	73 0b                	jae    f010123a <sprintputch+0x1a>
		*b->buf++ = ch;
f010122f:	8b 4c 24 04          	mov    0x4(%esp),%ecx
f0101233:	88 0a                	mov    %cl,(%edx)
f0101235:	83 c2 01             	add    $0x1,%edx
f0101238:	89 10                	mov    %edx,(%eax)
f010123a:	f3 c3                	repz ret 

f010123c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010123c:	83 ec 1c             	sub    $0x1c,%esp
	va_list ap;

	va_start(ap, fmt);
	vprintfmt(putch, putdat, fmt, ap);
f010123f:	8d 44 24 2c          	lea    0x2c(%esp),%eax
f0101243:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101247:	8b 44 24 28          	mov    0x28(%esp),%eax
f010124b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010124f:	8b 44 24 24          	mov    0x24(%esp),%eax
f0101253:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101257:	8b 44 24 20          	mov    0x20(%esp),%eax
f010125b:	89 04 24             	mov    %eax,(%esp)
f010125e:	e8 04 00 00 00       	call   f0101267 <vprintfmt>
	va_end(ap);
}
f0101263:	83 c4 1c             	add    $0x1c,%esp
f0101266:	c3                   	ret    

f0101267 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0101267:	55                   	push   %ebp
f0101268:	57                   	push   %edi
f0101269:	56                   	push   %esi
f010126a:	53                   	push   %ebx
f010126b:	83 ec 4c             	sub    $0x4c,%esp
f010126e:	8b 6c 24 60          	mov    0x60(%esp),%ebp
f0101272:	8b 5c 24 64          	mov    0x64(%esp),%ebx
f0101276:	8b 74 24 68          	mov    0x68(%esp),%esi
f010127a:	eb 11                	jmp    f010128d <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010127c:	85 c0                	test   %eax,%eax
f010127e:	0f 84 14 04 00 00    	je     f0101698 <vprintfmt+0x431>
				return;
			putch(ch, putdat);
f0101284:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101288:	89 04 24             	mov    %eax,(%esp)
f010128b:	ff d5                	call   *%ebp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010128d:	0f b6 06             	movzbl (%esi),%eax
f0101290:	83 c6 01             	add    $0x1,%esi
f0101293:	83 f8 25             	cmp    $0x25,%eax
f0101296:	75 e4                	jne    f010127c <vprintfmt+0x15>
f0101298:	c6 44 24 2c 20       	movb   $0x20,0x2c(%esp)
f010129d:	c7 44 24 30 00 00 00 	movl   $0x0,0x30(%esp)
f01012a4:	00 
f01012a5:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f01012aa:	c7 44 24 34 ff ff ff 	movl   $0xffffffff,0x34(%esp)
f01012b1:	ff 
f01012b2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012b7:	89 7c 24 38          	mov    %edi,0x38(%esp)
f01012bb:	eb 34                	jmp    f01012f1 <vprintfmt+0x8a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012bd:	8b 74 24 28          	mov    0x28(%esp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f01012c1:	c6 44 24 2c 2d       	movb   $0x2d,0x2c(%esp)
f01012c6:	eb 29                	jmp    f01012f1 <vprintfmt+0x8a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012c8:	8b 74 24 28          	mov    0x28(%esp),%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01012cc:	c6 44 24 2c 30       	movb   $0x30,0x2c(%esp)
f01012d1:	eb 1e                	jmp    f01012f1 <vprintfmt+0x8a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012d3:	8b 74 24 28          	mov    0x28(%esp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f01012d7:	c7 44 24 34 00 00 00 	movl   $0x0,0x34(%esp)
f01012de:	00 
f01012df:	eb 10                	jmp    f01012f1 <vprintfmt+0x8a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01012e1:	8b 44 24 38          	mov    0x38(%esp),%eax
f01012e5:	89 44 24 34          	mov    %eax,0x34(%esp)
f01012e9:	c7 44 24 38 ff ff ff 	movl   $0xffffffff,0x38(%esp)
f01012f0:	ff 
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012f1:	0f b6 06             	movzbl (%esi),%eax
f01012f4:	0f b6 d0             	movzbl %al,%edx
f01012f7:	8d 7e 01             	lea    0x1(%esi),%edi
f01012fa:	89 7c 24 28          	mov    %edi,0x28(%esp)
f01012fe:	83 e8 23             	sub    $0x23,%eax
f0101301:	3c 55                	cmp    $0x55,%al
f0101303:	0f 87 6a 03 00 00    	ja     f0101673 <vprintfmt+0x40c>
f0101309:	0f b6 c0             	movzbl %al,%eax
f010130c:	ff 24 85 dc 24 10 f0 	jmp    *-0xfefdb24(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0101313:	83 ea 30             	sub    $0x30,%edx
f0101316:	89 54 24 38          	mov    %edx,0x38(%esp)
				ch = *fmt;
f010131a:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f010131e:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101321:	8b 74 24 28          	mov    0x28(%esp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f0101325:	83 fa 09             	cmp    $0x9,%edx
f0101328:	77 57                	ja     f0101381 <vprintfmt+0x11a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010132a:	8b 7c 24 38          	mov    0x38(%esp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010132e:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0101331:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f0101334:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0101338:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010133b:	8d 50 d0             	lea    -0x30(%eax),%edx
f010133e:	83 fa 09             	cmp    $0x9,%edx
f0101341:	76 eb                	jbe    f010132e <vprintfmt+0xc7>
f0101343:	89 7c 24 38          	mov    %edi,0x38(%esp)
f0101347:	eb 38                	jmp    f0101381 <vprintfmt+0x11a>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101349:	8b 44 24 6c          	mov    0x6c(%esp),%eax
f010134d:	8d 50 04             	lea    0x4(%eax),%edx
f0101350:	89 54 24 6c          	mov    %edx,0x6c(%esp)
f0101354:	8b 00                	mov    (%eax),%eax
f0101356:	89 44 24 38          	mov    %eax,0x38(%esp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010135a:	8b 74 24 28          	mov    0x28(%esp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f010135e:	eb 21                	jmp    f0101381 <vprintfmt+0x11a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101360:	8b 74 24 28          	mov    0x28(%esp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f0101364:	83 7c 24 34 00       	cmpl   $0x0,0x34(%esp)
f0101369:	79 86                	jns    f01012f1 <vprintfmt+0x8a>
f010136b:	e9 63 ff ff ff       	jmp    f01012d3 <vprintfmt+0x6c>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101370:	8b 74 24 28          	mov    0x28(%esp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0101374:	c7 44 24 30 01 00 00 	movl   $0x1,0x30(%esp)
f010137b:	00 
			goto reswitch;
f010137c:	e9 70 ff ff ff       	jmp    f01012f1 <vprintfmt+0x8a>

		process_precision:
			if (width < 0)
f0101381:	83 7c 24 34 00       	cmpl   $0x0,0x34(%esp)
f0101386:	0f 89 65 ff ff ff    	jns    f01012f1 <vprintfmt+0x8a>
f010138c:	e9 50 ff ff ff       	jmp    f01012e1 <vprintfmt+0x7a>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101391:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101394:	8b 74 24 28          	mov    0x28(%esp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0101398:	e9 54 ff ff ff       	jmp    f01012f1 <vprintfmt+0x8a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010139d:	8b 44 24 6c          	mov    0x6c(%esp),%eax
f01013a1:	8d 50 04             	lea    0x4(%eax),%edx
f01013a4:	89 54 24 6c          	mov    %edx,0x6c(%esp)
f01013a8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01013ac:	8b 00                	mov    (%eax),%eax
f01013ae:	89 04 24             	mov    %eax,(%esp)
f01013b1:	ff d5                	call   *%ebp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01013b3:	8b 74 24 28          	mov    0x28(%esp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01013b7:	e9 d1 fe ff ff       	jmp    f010128d <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01013bc:	8b 44 24 6c          	mov    0x6c(%esp),%eax
f01013c0:	8d 50 04             	lea    0x4(%eax),%edx
f01013c3:	89 54 24 6c          	mov    %edx,0x6c(%esp)
f01013c7:	8b 00                	mov    (%eax),%eax
f01013c9:	89 c2                	mov    %eax,%edx
f01013cb:	c1 fa 1f             	sar    $0x1f,%edx
f01013ce:	31 d0                	xor    %edx,%eax
f01013d0:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
f01013d2:	83 f8 06             	cmp    $0x6,%eax
f01013d5:	7f 0b                	jg     f01013e2 <vprintfmt+0x17b>
f01013d7:	8b 14 85 34 26 10 f0 	mov    -0xfefd9cc(,%eax,4),%edx
f01013de:	85 d2                	test   %edx,%edx
f01013e0:	75 21                	jne    f0101403 <vprintfmt+0x19c>
				printfmt(putch, putdat, "error %d", err);
f01013e2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01013e6:	c7 44 24 08 65 24 10 	movl   $0xf0102465,0x8(%esp)
f01013ed:	f0 
f01013ee:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01013f2:	89 2c 24             	mov    %ebp,(%esp)
f01013f5:	e8 42 fe ff ff       	call   f010123c <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01013fa:	8b 74 24 28          	mov    0x28(%esp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01013fe:	e9 8a fe ff ff       	jmp    f010128d <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0101403:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101407:	c7 44 24 08 6e 24 10 	movl   $0xf010246e,0x8(%esp)
f010140e:	f0 
f010140f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101413:	89 2c 24             	mov    %ebp,(%esp)
f0101416:	e8 21 fe ff ff       	call   f010123c <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010141b:	8b 74 24 28          	mov    0x28(%esp),%esi
f010141f:	e9 69 fe ff ff       	jmp    f010128d <vprintfmt+0x26>
f0101424:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101428:	8b 44 24 34          	mov    0x34(%esp),%eax
f010142c:	89 44 24 38          	mov    %eax,0x38(%esp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101430:	8b 44 24 6c          	mov    0x6c(%esp),%eax
f0101434:	8d 50 04             	lea    0x4(%eax),%edx
f0101437:	89 54 24 6c          	mov    %edx,0x6c(%esp)
f010143b:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010143d:	85 f6                	test   %esi,%esi
f010143f:	ba 5e 24 10 f0       	mov    $0xf010245e,%edx
f0101444:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f0101447:	83 7c 24 38 00       	cmpl   $0x0,0x38(%esp)
f010144c:	7e 07                	jle    f0101455 <vprintfmt+0x1ee>
f010144e:	80 7c 24 2c 2d       	cmpb   $0x2d,0x2c(%esp)
f0101453:	75 13                	jne    f0101468 <vprintfmt+0x201>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101455:	0f be 06             	movsbl (%esi),%eax
f0101458:	83 c6 01             	add    $0x1,%esi
f010145b:	85 c0                	test   %eax,%eax
f010145d:	0f 85 9c 00 00 00    	jne    f01014ff <vprintfmt+0x298>
f0101463:	e9 87 00 00 00       	jmp    f01014ef <vprintfmt+0x288>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101468:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010146c:	89 34 24             	mov    %esi,(%esp)
f010146f:	e8 95 03 00 00       	call   f0101809 <strnlen>
f0101474:	8b 4c 24 38          	mov    0x38(%esp),%ecx
f0101478:	29 c1                	sub    %eax,%ecx
f010147a:	89 4c 24 34          	mov    %ecx,0x34(%esp)
f010147e:	85 c9                	test   %ecx,%ecx
f0101480:	7e d3                	jle    f0101455 <vprintfmt+0x1ee>
					putch(padc, putdat);
f0101482:	0f be 44 24 2c       	movsbl 0x2c(%esp),%eax
f0101487:	89 74 24 38          	mov    %esi,0x38(%esp)
f010148b:	89 7c 24 3c          	mov    %edi,0x3c(%esp)
f010148f:	89 ce                	mov    %ecx,%esi
f0101491:	89 c7                	mov    %eax,%edi
f0101493:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101497:	89 3c 24             	mov    %edi,(%esp)
f010149a:	ff d5                	call   *%ebp
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010149c:	83 ee 01             	sub    $0x1,%esi
f010149f:	75 f2                	jne    f0101493 <vprintfmt+0x22c>
f01014a1:	8b 7c 24 3c          	mov    0x3c(%esp),%edi
f01014a5:	89 74 24 34          	mov    %esi,0x34(%esp)
f01014a9:	8b 74 24 38          	mov    0x38(%esp),%esi
f01014ad:	eb a6                	jmp    f0101455 <vprintfmt+0x1ee>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01014af:	83 7c 24 30 00       	cmpl   $0x0,0x30(%esp)
f01014b4:	74 19                	je     f01014cf <vprintfmt+0x268>
f01014b6:	8d 50 e0             	lea    -0x20(%eax),%edx
f01014b9:	83 fa 5e             	cmp    $0x5e,%edx
f01014bc:	76 11                	jbe    f01014cf <vprintfmt+0x268>
					putch('?', putdat);
f01014be:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01014c2:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01014c9:	ff 54 24 2c          	call   *0x2c(%esp)
f01014cd:	eb 0b                	jmp    f01014da <vprintfmt+0x273>
				else
					putch(ch, putdat);
f01014cf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01014d3:	89 04 24             	mov    %eax,(%esp)
f01014d6:	ff 54 24 2c          	call   *0x2c(%esp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01014da:	83 ed 01             	sub    $0x1,%ebp
f01014dd:	0f be 06             	movsbl (%esi),%eax
f01014e0:	83 c6 01             	add    $0x1,%esi
f01014e3:	85 c0                	test   %eax,%eax
f01014e5:	75 20                	jne    f0101507 <vprintfmt+0x2a0>
f01014e7:	89 6c 24 34          	mov    %ebp,0x34(%esp)
f01014eb:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01014ef:	8b 74 24 28          	mov    0x28(%esp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01014f3:	83 7c 24 34 00       	cmpl   $0x0,0x34(%esp)
f01014f8:	7f 20                	jg     f010151a <vprintfmt+0x2b3>
f01014fa:	e9 8e fd ff ff       	jmp    f010128d <vprintfmt+0x26>
f01014ff:	89 6c 24 2c          	mov    %ebp,0x2c(%esp)
f0101503:	8b 6c 24 34          	mov    0x34(%esp),%ebp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101507:	85 ff                	test   %edi,%edi
f0101509:	78 a4                	js     f01014af <vprintfmt+0x248>
f010150b:	83 ef 01             	sub    $0x1,%edi
f010150e:	79 9f                	jns    f01014af <vprintfmt+0x248>
f0101510:	89 6c 24 34          	mov    %ebp,0x34(%esp)
f0101514:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0101518:	eb d5                	jmp    f01014ef <vprintfmt+0x288>
f010151a:	8b 74 24 34          	mov    0x34(%esp),%esi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010151e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101522:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101529:	ff d5                	call   *%ebp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010152b:	83 ee 01             	sub    $0x1,%esi
f010152e:	75 ee                	jne    f010151e <vprintfmt+0x2b7>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101530:	8b 74 24 28          	mov    0x28(%esp),%esi
f0101534:	e9 54 fd ff ff       	jmp    f010128d <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101539:	83 f9 01             	cmp    $0x1,%ecx
f010153c:	7e 12                	jle    f0101550 <vprintfmt+0x2e9>
		return va_arg(*ap, long long);
f010153e:	8b 44 24 6c          	mov    0x6c(%esp),%eax
f0101542:	8d 50 08             	lea    0x8(%eax),%edx
f0101545:	89 54 24 6c          	mov    %edx,0x6c(%esp)
f0101549:	8b 30                	mov    (%eax),%esi
f010154b:	8b 78 04             	mov    0x4(%eax),%edi
f010154e:	eb 2a                	jmp    f010157a <vprintfmt+0x313>
	else if (lflag)
f0101550:	85 c9                	test   %ecx,%ecx
f0101552:	74 14                	je     f0101568 <vprintfmt+0x301>
		return va_arg(*ap, long);
f0101554:	8b 44 24 6c          	mov    0x6c(%esp),%eax
f0101558:	8d 50 04             	lea    0x4(%eax),%edx
f010155b:	89 54 24 6c          	mov    %edx,0x6c(%esp)
f010155f:	8b 30                	mov    (%eax),%esi
f0101561:	89 f7                	mov    %esi,%edi
f0101563:	c1 ff 1f             	sar    $0x1f,%edi
f0101566:	eb 12                	jmp    f010157a <vprintfmt+0x313>
	else
		return va_arg(*ap, int);
f0101568:	8b 44 24 6c          	mov    0x6c(%esp),%eax
f010156c:	8d 50 04             	lea    0x4(%eax),%edx
f010156f:	89 54 24 6c          	mov    %edx,0x6c(%esp)
f0101573:	8b 30                	mov    (%eax),%esi
f0101575:	89 f7                	mov    %esi,%edi
f0101577:	c1 ff 1f             	sar    $0x1f,%edi
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010157a:	85 ff                	test   %edi,%edi
f010157c:	78 0e                	js     f010158c <vprintfmt+0x325>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010157e:	89 f0                	mov    %esi,%eax
f0101580:	89 fa                	mov    %edi,%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101582:	be 0a 00 00 00       	mov    $0xa,%esi
f0101587:	e9 a7 00 00 00       	jmp    f0101633 <vprintfmt+0x3cc>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
f010158c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101590:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101597:	ff d5                	call   *%ebp
				num = -(long long) num;
f0101599:	89 f0                	mov    %esi,%eax
f010159b:	89 fa                	mov    %edi,%edx
f010159d:	f7 d8                	neg    %eax
f010159f:	83 d2 00             	adc    $0x0,%edx
f01015a2:	f7 da                	neg    %edx
			}
			base = 10;
f01015a4:	be 0a 00 00 00       	mov    $0xa,%esi
f01015a9:	e9 85 00 00 00       	jmp    f0101633 <vprintfmt+0x3cc>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01015ae:	89 ca                	mov    %ecx,%edx
f01015b0:	8d 44 24 6c          	lea    0x6c(%esp),%eax
f01015b4:	e8 33 fc ff ff       	call   f01011ec <getuint>
			base = 10;
f01015b9:	be 0a 00 00 00       	mov    $0xa,%esi
			goto number;
f01015be:	eb 73                	jmp    f0101633 <vprintfmt+0x3cc>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f01015c0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01015c4:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01015cb:	ff d5                	call   *%ebp
			putch('X', putdat);
f01015cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01015d1:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01015d8:	ff d5                	call   *%ebp
			putch('X', putdat);
f01015da:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01015de:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01015e5:	ff d5                	call   *%ebp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01015e7:	8b 74 24 28          	mov    0x28(%esp),%esi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f01015eb:	e9 9d fc ff ff       	jmp    f010128d <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f01015f0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01015f4:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01015fb:	ff d5                	call   *%ebp
			putch('x', putdat);
f01015fd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101601:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101608:	ff d5                	call   *%ebp
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010160a:	8b 44 24 6c          	mov    0x6c(%esp),%eax
f010160e:	8d 50 04             	lea    0x4(%eax),%edx
f0101611:	89 54 24 6c          	mov    %edx,0x6c(%esp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101615:	8b 00                	mov    (%eax),%eax
f0101617:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010161c:	be 10 00 00 00       	mov    $0x10,%esi
			goto number;
f0101621:	eb 10                	jmp    f0101633 <vprintfmt+0x3cc>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101623:	89 ca                	mov    %ecx,%edx
f0101625:	8d 44 24 6c          	lea    0x6c(%esp),%eax
f0101629:	e8 be fb ff ff       	call   f01011ec <getuint>
			base = 16;
f010162e:	be 10 00 00 00       	mov    $0x10,%esi
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101633:	0f be 4c 24 2c       	movsbl 0x2c(%esp),%ecx
f0101638:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010163c:	8b 7c 24 34          	mov    0x34(%esp),%edi
f0101640:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101644:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101648:	89 04 24             	mov    %eax,(%esp)
f010164b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010164f:	89 da                	mov    %ebx,%edx
f0101651:	89 e8                	mov    %ebp,%eax
f0101653:	e8 b0 fa ff ff       	call   f0101108 <printnum>
			break;
f0101658:	8b 74 24 28          	mov    0x28(%esp),%esi
f010165c:	e9 2c fc ff ff       	jmp    f010128d <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101661:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101665:	89 14 24             	mov    %edx,(%esp)
f0101668:	ff d5                	call   *%ebp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010166a:	8b 74 24 28          	mov    0x28(%esp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010166e:	e9 1a fc ff ff       	jmp    f010128d <vprintfmt+0x26>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101673:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101677:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f010167e:	ff d5                	call   *%ebp
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101680:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101684:	0f 84 03 fc ff ff    	je     f010128d <vprintfmt+0x26>
f010168a:	83 ee 01             	sub    $0x1,%esi
f010168d:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101691:	75 f7                	jne    f010168a <vprintfmt+0x423>
f0101693:	e9 f5 fb ff ff       	jmp    f010128d <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101698:	83 c4 4c             	add    $0x4c,%esp
f010169b:	5b                   	pop    %ebx
f010169c:	5e                   	pop    %esi
f010169d:	5f                   	pop    %edi
f010169e:	5d                   	pop    %ebp
f010169f:	c3                   	ret    

f01016a0 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01016a0:	83 ec 2c             	sub    $0x2c,%esp
f01016a3:	8b 44 24 30          	mov    0x30(%esp),%eax
f01016a7:	8b 54 24 34          	mov    0x34(%esp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01016ab:	89 44 24 14          	mov    %eax,0x14(%esp)
f01016af:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01016b3:	89 4c 24 18          	mov    %ecx,0x18(%esp)
f01016b7:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
f01016be:	00 

	if (buf == NULL || n < 1)
f01016bf:	85 c0                	test   %eax,%eax
f01016c1:	74 35                	je     f01016f8 <vsnprintf+0x58>
f01016c3:	85 d2                	test   %edx,%edx
f01016c5:	7e 31                	jle    f01016f8 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01016c7:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f01016cb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016cf:	8b 44 24 38          	mov    0x38(%esp),%eax
f01016d3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01016d7:	8d 44 24 14          	lea    0x14(%esp),%eax
f01016db:	89 44 24 04          	mov    %eax,0x4(%esp)
f01016df:	c7 04 24 20 12 10 f0 	movl   $0xf0101220,(%esp)
f01016e6:	e8 7c fb ff ff       	call   f0101267 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01016eb:	8b 44 24 14          	mov    0x14(%esp),%eax
f01016ef:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01016f2:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f01016f6:	eb 05                	jmp    f01016fd <vsnprintf+0x5d>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01016f8:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01016fd:	83 c4 2c             	add    $0x2c,%esp
f0101700:	c3                   	ret    

f0101701 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101701:	83 ec 1c             	sub    $0x1c,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
	rc = vsnprintf(buf, n, fmt, ap);
f0101704:	8d 44 24 2c          	lea    0x2c(%esp),%eax
f0101708:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010170c:	8b 44 24 28          	mov    0x28(%esp),%eax
f0101710:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101714:	8b 44 24 24          	mov    0x24(%esp),%eax
f0101718:	89 44 24 04          	mov    %eax,0x4(%esp)
f010171c:	8b 44 24 20          	mov    0x20(%esp),%eax
f0101720:	89 04 24             	mov    %eax,(%esp)
f0101723:	e8 78 ff ff ff       	call   f01016a0 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101728:	83 c4 1c             	add    $0x1c,%esp
f010172b:	c3                   	ret    
f010172c:	00 00                	add    %al,(%eax)
	...

f0101730 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101730:	57                   	push   %edi
f0101731:	56                   	push   %esi
f0101732:	53                   	push   %ebx
f0101733:	83 ec 10             	sub    $0x10,%esp
f0101736:	8b 44 24 20          	mov    0x20(%esp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010173a:	85 c0                	test   %eax,%eax
f010173c:	74 10                	je     f010174e <readline+0x1e>
		cprintf("%s", prompt);
f010173e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101742:	c7 04 24 6e 24 10 f0 	movl   $0xf010246e,(%esp)
f0101749:	e8 cc f6 ff ff       	call   f0100e1a <cprintf>

	i = 0;
	echoing = iscons(0);
f010174e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101755:	e8 b5 ee ff ff       	call   f010060f <iscons>
f010175a:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010175c:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101761:	e8 99 ee ff ff       	call   f01005ff <getchar>
f0101766:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101768:	85 c0                	test   %eax,%eax
f010176a:	79 17                	jns    f0101783 <readline+0x53>
			cprintf("read error: %e\n", c);
f010176c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101770:	c7 04 24 50 26 10 f0 	movl   $0xf0102650,(%esp)
f0101777:	e8 9e f6 ff ff       	call   f0100e1a <cprintf>
			return NULL;
f010177c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101781:	eb 63                	jmp    f01017e6 <readline+0xb6>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101783:	83 f8 1f             	cmp    $0x1f,%eax
f0101786:	7e 1f                	jle    f01017a7 <readline+0x77>
f0101788:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010178e:	7f 17                	jg     f01017a7 <readline+0x77>
			if (echoing)
f0101790:	85 ff                	test   %edi,%edi
f0101792:	74 08                	je     f010179c <readline+0x6c>
				cputchar(c);
f0101794:	89 04 24             	mov    %eax,(%esp)
f0101797:	e8 50 ee ff ff       	call   f01005ec <cputchar>
			buf[i++] = c;
f010179c:	88 9e 00 26 11 f0    	mov    %bl,-0xfeeda00(%esi)
f01017a2:	83 c6 01             	add    $0x1,%esi
f01017a5:	eb ba                	jmp    f0101761 <readline+0x31>
		} else if (c == '\b' && i > 0) {
f01017a7:	83 fb 08             	cmp    $0x8,%ebx
f01017aa:	75 15                	jne    f01017c1 <readline+0x91>
f01017ac:	85 f6                	test   %esi,%esi
f01017ae:	7e 11                	jle    f01017c1 <readline+0x91>
			if (echoing)
f01017b0:	85 ff                	test   %edi,%edi
f01017b2:	74 08                	je     f01017bc <readline+0x8c>
				cputchar(c);
f01017b4:	89 1c 24             	mov    %ebx,(%esp)
f01017b7:	e8 30 ee ff ff       	call   f01005ec <cputchar>
			i--;
f01017bc:	83 ee 01             	sub    $0x1,%esi
f01017bf:	eb a0                	jmp    f0101761 <readline+0x31>
		} else if (c == '\n' || c == '\r') {
f01017c1:	83 fb 0a             	cmp    $0xa,%ebx
f01017c4:	74 05                	je     f01017cb <readline+0x9b>
f01017c6:	83 fb 0d             	cmp    $0xd,%ebx
f01017c9:	75 96                	jne    f0101761 <readline+0x31>
			if (echoing)
f01017cb:	85 ff                	test   %edi,%edi
f01017cd:	8d 76 00             	lea    0x0(%esi),%esi
f01017d0:	74 08                	je     f01017da <readline+0xaa>
				cputchar(c);
f01017d2:	89 1c 24             	mov    %ebx,(%esp)
f01017d5:	e8 12 ee ff ff       	call   f01005ec <cputchar>
			buf[i] = 0;
f01017da:	c6 86 00 26 11 f0 00 	movb   $0x0,-0xfeeda00(%esi)
			return buf;
f01017e1:	b8 00 26 11 f0       	mov    $0xf0112600,%eax
		}
	}
}
f01017e6:	83 c4 10             	add    $0x10,%esp
f01017e9:	5b                   	pop    %ebx
f01017ea:	5e                   	pop    %esi
f01017eb:	5f                   	pop    %edi
f01017ec:	c3                   	ret    
f01017ed:	00 00                	add    %al,(%eax)
	...

f01017f0 <strlen>:

#include <inc/string.h>

int
strlen(const char *s)
{
f01017f0:	8b 54 24 04          	mov    0x4(%esp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01017f4:	b8 00 00 00 00       	mov    $0x0,%eax
f01017f9:	80 3a 00             	cmpb   $0x0,(%edx)
f01017fc:	74 09                	je     f0101807 <strlen+0x17>
		n++;
f01017fe:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101801:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101805:	75 f7                	jne    f01017fe <strlen+0xe>
		n++;
	return n;
}
f0101807:	f3 c3                	repz ret 

f0101809 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101809:	53                   	push   %ebx
f010180a:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f010180e:	8b 4c 24 0c          	mov    0xc(%esp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101812:	b8 00 00 00 00       	mov    $0x0,%eax
f0101817:	85 c9                	test   %ecx,%ecx
f0101819:	74 1a                	je     f0101835 <strnlen+0x2c>
f010181b:	80 3b 00             	cmpb   $0x0,(%ebx)
f010181e:	74 15                	je     f0101835 <strnlen+0x2c>
f0101820:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0101825:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101827:	39 ca                	cmp    %ecx,%edx
f0101829:	74 0a                	je     f0101835 <strnlen+0x2c>
f010182b:	83 c2 01             	add    $0x1,%edx
f010182e:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101833:	75 f0                	jne    f0101825 <strnlen+0x1c>
		n++;
	return n;
}
f0101835:	5b                   	pop    %ebx
f0101836:	c3                   	ret    

f0101837 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101837:	53                   	push   %ebx
f0101838:	8b 44 24 08          	mov    0x8(%esp),%eax
f010183c:	8b 5c 24 0c          	mov    0xc(%esp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101840:	ba 00 00 00 00       	mov    $0x0,%edx
f0101845:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0101849:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f010184c:	83 c2 01             	add    $0x1,%edx
f010184f:	84 c9                	test   %cl,%cl
f0101851:	75 f2                	jne    f0101845 <strcpy+0xe>
		/* do nothing */;
	return ret;
}
f0101853:	5b                   	pop    %ebx
f0101854:	c3                   	ret    

f0101855 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101855:	56                   	push   %esi
f0101856:	53                   	push   %ebx
f0101857:	8b 44 24 0c          	mov    0xc(%esp),%eax
f010185b:	8b 54 24 10          	mov    0x10(%esp),%edx
f010185f:	8b 74 24 14          	mov    0x14(%esp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101863:	85 f6                	test   %esi,%esi
f0101865:	74 18                	je     f010187f <strncpy+0x2a>
f0101867:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f010186c:	0f b6 1a             	movzbl (%edx),%ebx
f010186f:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101872:	80 3a 01             	cmpb   $0x1,(%edx)
f0101875:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101878:	83 c1 01             	add    $0x1,%ecx
f010187b:	39 f1                	cmp    %esi,%ecx
f010187d:	75 ed                	jne    f010186c <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010187f:	5b                   	pop    %ebx
f0101880:	5e                   	pop    %esi
f0101881:	c3                   	ret    

f0101882 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101882:	57                   	push   %edi
f0101883:	56                   	push   %esi
f0101884:	53                   	push   %ebx
f0101885:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0101889:	8b 5c 24 14          	mov    0x14(%esp),%ebx
f010188d:	8b 74 24 18          	mov    0x18(%esp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101891:	89 f8                	mov    %edi,%eax
f0101893:	85 f6                	test   %esi,%esi
f0101895:	74 2b                	je     f01018c2 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0101897:	83 fe 01             	cmp    $0x1,%esi
f010189a:	74 23                	je     f01018bf <strlcpy+0x3d>
f010189c:	0f b6 0b             	movzbl (%ebx),%ecx
f010189f:	84 c9                	test   %cl,%cl
f01018a1:	74 1c                	je     f01018bf <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f01018a3:	83 ee 02             	sub    $0x2,%esi
f01018a6:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01018ab:	88 08                	mov    %cl,(%eax)
f01018ad:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01018b0:	39 f2                	cmp    %esi,%edx
f01018b2:	74 0b                	je     f01018bf <strlcpy+0x3d>
f01018b4:	83 c2 01             	add    $0x1,%edx
f01018b7:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01018bb:	84 c9                	test   %cl,%cl
f01018bd:	75 ec                	jne    f01018ab <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f01018bf:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01018c2:	29 f8                	sub    %edi,%eax
}
f01018c4:	5b                   	pop    %ebx
f01018c5:	5e                   	pop    %esi
f01018c6:	5f                   	pop    %edi
f01018c7:	c3                   	ret    

f01018c8 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01018c8:	8b 4c 24 04          	mov    0x4(%esp),%ecx
f01018cc:	8b 54 24 08          	mov    0x8(%esp),%edx
	while (*p && *p == *q)
f01018d0:	0f b6 01             	movzbl (%ecx),%eax
f01018d3:	84 c0                	test   %al,%al
f01018d5:	74 16                	je     f01018ed <strcmp+0x25>
f01018d7:	3a 02                	cmp    (%edx),%al
f01018d9:	75 12                	jne    f01018ed <strcmp+0x25>
		p++, q++;
f01018db:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01018de:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f01018e2:	84 c0                	test   %al,%al
f01018e4:	74 07                	je     f01018ed <strcmp+0x25>
f01018e6:	83 c1 01             	add    $0x1,%ecx
f01018e9:	3a 02                	cmp    (%edx),%al
f01018eb:	74 ee                	je     f01018db <strcmp+0x13>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01018ed:	0f b6 c0             	movzbl %al,%eax
f01018f0:	0f b6 12             	movzbl (%edx),%edx
f01018f3:	29 d0                	sub    %edx,%eax
}
f01018f5:	c3                   	ret    

f01018f6 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01018f6:	53                   	push   %ebx
f01018f7:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f01018fb:	8b 5c 24 0c          	mov    0xc(%esp),%ebx
f01018ff:	8b 54 24 10          	mov    0x10(%esp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101903:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101908:	85 d2                	test   %edx,%edx
f010190a:	74 28                	je     f0101934 <strncmp+0x3e>
f010190c:	0f b6 01             	movzbl (%ecx),%eax
f010190f:	84 c0                	test   %al,%al
f0101911:	74 23                	je     f0101936 <strncmp+0x40>
f0101913:	3a 03                	cmp    (%ebx),%al
f0101915:	75 1f                	jne    f0101936 <strncmp+0x40>
f0101917:	83 ea 01             	sub    $0x1,%edx
f010191a:	74 13                	je     f010192f <strncmp+0x39>
		n--, p++, q++;
f010191c:	83 c1 01             	add    $0x1,%ecx
f010191f:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101922:	0f b6 01             	movzbl (%ecx),%eax
f0101925:	84 c0                	test   %al,%al
f0101927:	74 0d                	je     f0101936 <strncmp+0x40>
f0101929:	3a 03                	cmp    (%ebx),%al
f010192b:	74 ea                	je     f0101917 <strncmp+0x21>
f010192d:	eb 07                	jmp    f0101936 <strncmp+0x40>
		n--, p++, q++;
	if (n == 0)
		return 0;
f010192f:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101934:	5b                   	pop    %ebx
f0101935:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101936:	0f b6 01             	movzbl (%ecx),%eax
f0101939:	0f b6 13             	movzbl (%ebx),%edx
f010193c:	29 d0                	sub    %edx,%eax
f010193e:	eb f4                	jmp    f0101934 <strncmp+0x3e>

f0101940 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101940:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101944:	0f b6 4c 24 08       	movzbl 0x8(%esp),%ecx
	for (; *s; s++)
f0101949:	0f b6 10             	movzbl (%eax),%edx
f010194c:	84 d2                	test   %dl,%dl
f010194e:	74 1b                	je     f010196b <strchr+0x2b>
		if (*s == c)
f0101950:	38 ca                	cmp    %cl,%dl
f0101952:	75 09                	jne    f010195d <strchr+0x1d>
f0101954:	f3 c3                	repz ret 
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101956:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0101959:	38 ca                	cmp    %cl,%dl
f010195b:	74 13                	je     f0101970 <strchr+0x30>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010195d:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f0101961:	84 d2                	test   %dl,%dl
f0101963:	75 f1                	jne    f0101956 <strchr+0x16>
		if (*s == c)
			return (char *) s;
	return 0;
f0101965:	b8 00 00 00 00       	mov    $0x0,%eax
f010196a:	c3                   	ret    
f010196b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101970:	f3 c3                	repz ret 

f0101972 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101972:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101976:	0f b6 4c 24 08       	movzbl 0x8(%esp),%ecx
	for (; *s; s++)
f010197b:	0f b6 10             	movzbl (%eax),%edx
f010197e:	84 d2                	test   %dl,%dl
f0101980:	74 1a                	je     f010199c <strfind+0x2a>
		if (*s == c)
f0101982:	38 ca                	cmp    %cl,%dl
f0101984:	75 0c                	jne    f0101992 <strfind+0x20>
f0101986:	f3 c3                	repz ret 
f0101988:	38 ca                	cmp    %cl,%dl
f010198a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101990:	74 0a                	je     f010199c <strfind+0x2a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101992:	83 c0 01             	add    $0x1,%eax
f0101995:	0f b6 10             	movzbl (%eax),%edx
f0101998:	84 d2                	test   %dl,%dl
f010199a:	75 ec                	jne    f0101988 <strfind+0x16>
		if (*s == c)
			break;
	return (char *) s;
}
f010199c:	f3 c3                	repz ret 

f010199e <memset>:


void *
memset(void *v, int c, size_t n)
{
f010199e:	53                   	push   %ebx
f010199f:	8b 44 24 08          	mov    0x8(%esp),%eax
f01019a3:	8b 4c 24 0c          	mov    0xc(%esp),%ecx
f01019a7:	8b 5c 24 10          	mov    0x10(%esp),%ebx
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f01019ab:	89 da                	mov    %ebx,%edx
f01019ad:	83 ea 01             	sub    $0x1,%edx
f01019b0:	78 0d                	js     f01019bf <memset+0x21>
	return (char *) s;
}


void *
memset(void *v, int c, size_t n)
f01019b2:	01 c3                	add    %eax,%ebx
{
	char *p;
	int m;

	p = v;
f01019b4:	89 c2                	mov    %eax,%edx
	m = n;
	while (--m >= 0)
		*p++ = c;
f01019b6:	88 0a                	mov    %cl,(%edx)
f01019b8:	83 c2 01             	add    $0x1,%edx
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f01019bb:	39 da                	cmp    %ebx,%edx
f01019bd:	75 f7                	jne    f01019b6 <memset+0x18>
		*p++ = c;

	return v;
}
f01019bf:	5b                   	pop    %ebx
f01019c0:	c3                   	ret    

f01019c1 <memmove>:

/* no memcpy - use memmove instead */

void *
memmove(void *dst, const void *src, size_t n)
{
f01019c1:	57                   	push   %edi
f01019c2:	56                   	push   %esi
f01019c3:	53                   	push   %ebx
f01019c4:	8b 44 24 10          	mov    0x10(%esp),%eax
f01019c8:	8b 74 24 14          	mov    0x14(%esp),%esi
f01019cc:	8b 5c 24 18          	mov    0x18(%esp),%ebx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01019d0:	39 c6                	cmp    %eax,%esi
f01019d2:	72 0b                	jb     f01019df <memmove+0x1e>
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f01019d4:	ba 00 00 00 00       	mov    $0x0,%edx
f01019d9:	85 db                	test   %ebx,%ebx
f01019db:	75 29                	jne    f0101a06 <memmove+0x45>
f01019dd:	eb 35                	jmp    f0101a14 <memmove+0x53>
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01019df:	8d 0c 1e             	lea    (%esi,%ebx,1),%ecx
f01019e2:	39 c8                	cmp    %ecx,%eax
f01019e4:	73 ee                	jae    f01019d4 <memmove+0x13>
		s += n;
		d += n;
		while (n-- > 0)
f01019e6:	85 db                	test   %ebx,%ebx
f01019e8:	74 2a                	je     f0101a14 <memmove+0x53>
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
f01019ea:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
f01019ed:	89 da                	mov    %ebx,%edx
}

/* no memcpy - use memmove instead */

void *
memmove(void *dst, const void *src, size_t n)
f01019ef:	f7 db                	neg    %ebx
f01019f1:	8d 34 19             	lea    (%ecx,%ebx,1),%esi
f01019f4:	01 fb                	add    %edi,%ebx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
f01019f6:	0f b6 4c 16 ff       	movzbl -0x1(%esi,%edx,1),%ecx
f01019fb:	88 4c 13 ff          	mov    %cl,-0x1(%ebx,%edx,1)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
f01019ff:	83 ea 01             	sub    $0x1,%edx
f0101a02:	75 f2                	jne    f01019f6 <memmove+0x35>
f0101a04:	eb 0e                	jmp    f0101a14 <memmove+0x53>
			*--d = *--s;
	} else
		while (n-- > 0)
			*d++ = *s++;
f0101a06:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0101a0a:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101a0d:	83 c2 01             	add    $0x1,%edx
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f0101a10:	39 d3                	cmp    %edx,%ebx
f0101a12:	75 f2                	jne    f0101a06 <memmove+0x45>
			*d++ = *s++;

	return dst;
}
f0101a14:	5b                   	pop    %ebx
f0101a15:	5e                   	pop    %esi
f0101a16:	5f                   	pop    %edi
f0101a17:	c3                   	ret    

f0101a18 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0101a18:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101a1b:	8b 44 24 18          	mov    0x18(%esp),%eax
f0101a1f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101a23:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101a27:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a2b:	8b 44 24 10          	mov    0x10(%esp),%eax
f0101a2f:	89 04 24             	mov    %eax,(%esp)
f0101a32:	e8 8a ff ff ff       	call   f01019c1 <memmove>
}
f0101a37:	83 c4 0c             	add    $0xc,%esp
f0101a3a:	c3                   	ret    

f0101a3b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101a3b:	57                   	push   %edi
f0101a3c:	56                   	push   %esi
f0101a3d:	53                   	push   %ebx
f0101a3e:	8b 5c 24 10          	mov    0x10(%esp),%ebx
f0101a42:	8b 74 24 14          	mov    0x14(%esp),%esi
f0101a46:	8b 7c 24 18          	mov    0x18(%esp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101a4a:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101a4f:	85 ff                	test   %edi,%edi
f0101a51:	74 37                	je     f0101a8a <memcmp+0x4f>
		if (*s1 != *s2)
f0101a53:	0f b6 03             	movzbl (%ebx),%eax
f0101a56:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101a59:	83 ef 01             	sub    $0x1,%edi
f0101a5c:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f0101a61:	38 c8                	cmp    %cl,%al
f0101a63:	74 1c                	je     f0101a81 <memcmp+0x46>
f0101a65:	eb 10                	jmp    f0101a77 <memcmp+0x3c>
f0101a67:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0101a6c:	83 c2 01             	add    $0x1,%edx
f0101a6f:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0101a73:	38 c8                	cmp    %cl,%al
f0101a75:	74 0a                	je     f0101a81 <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0101a77:	0f b6 c0             	movzbl %al,%eax
f0101a7a:	0f b6 c9             	movzbl %cl,%ecx
f0101a7d:	29 c8                	sub    %ecx,%eax
f0101a7f:	eb 09                	jmp    f0101a8a <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101a81:	39 fa                	cmp    %edi,%edx
f0101a83:	75 e2                	jne    f0101a67 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101a85:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101a8a:	5b                   	pop    %ebx
f0101a8b:	5e                   	pop    %esi
f0101a8c:	5f                   	pop    %edi
f0101a8d:	c3                   	ret    

f0101a8e <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101a8e:	8b 44 24 04          	mov    0x4(%esp),%eax
	const void *ends = (const char *) s + n;
f0101a92:	89 c2                	mov    %eax,%edx
f0101a94:	03 54 24 0c          	add    0xc(%esp),%edx
	for (; s < ends; s++)
f0101a98:	39 d0                	cmp    %edx,%eax
f0101a9a:	73 16                	jae    f0101ab2 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101a9c:	0f b6 4c 24 08       	movzbl 0x8(%esp),%ecx
f0101aa1:	38 08                	cmp    %cl,(%eax)
f0101aa3:	75 06                	jne    f0101aab <memfind+0x1d>
f0101aa5:	f3 c3                	repz ret 
f0101aa7:	38 08                	cmp    %cl,(%eax)
f0101aa9:	74 07                	je     f0101ab2 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101aab:	83 c0 01             	add    $0x1,%eax
f0101aae:	39 d0                	cmp    %edx,%eax
f0101ab0:	75 f5                	jne    f0101aa7 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101ab2:	f3 c3                	repz ret 

f0101ab4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101ab4:	55                   	push   %ebp
f0101ab5:	57                   	push   %edi
f0101ab6:	56                   	push   %esi
f0101ab7:	53                   	push   %ebx
f0101ab8:	8b 54 24 14          	mov    0x14(%esp),%edx
f0101abc:	8b 74 24 18          	mov    0x18(%esp),%esi
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101ac0:	0f b6 02             	movzbl (%edx),%eax
f0101ac3:	3c 20                	cmp    $0x20,%al
f0101ac5:	74 04                	je     f0101acb <strtol+0x17>
f0101ac7:	3c 09                	cmp    $0x9,%al
f0101ac9:	75 0e                	jne    f0101ad9 <strtol+0x25>
		s++;
f0101acb:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101ace:	0f b6 02             	movzbl (%edx),%eax
f0101ad1:	3c 20                	cmp    $0x20,%al
f0101ad3:	74 f6                	je     f0101acb <strtol+0x17>
f0101ad5:	3c 09                	cmp    $0x9,%al
f0101ad7:	74 f2                	je     f0101acb <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101ad9:	3c 2b                	cmp    $0x2b,%al
f0101adb:	75 0a                	jne    f0101ae7 <strtol+0x33>
		s++;
f0101add:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101ae0:	bf 00 00 00 00       	mov    $0x0,%edi
f0101ae5:	eb 10                	jmp    f0101af7 <strtol+0x43>
f0101ae7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101aec:	3c 2d                	cmp    $0x2d,%al
f0101aee:	75 07                	jne    f0101af7 <strtol+0x43>
		s++, neg = 1;
f0101af0:	83 c2 01             	add    $0x1,%edx
f0101af3:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101af7:	83 7c 24 1c 00       	cmpl   $0x0,0x1c(%esp)
f0101afc:	0f 94 c0             	sete   %al
f0101aff:	74 07                	je     f0101b08 <strtol+0x54>
f0101b01:	83 7c 24 1c 10       	cmpl   $0x10,0x1c(%esp)
f0101b06:	75 18                	jne    f0101b20 <strtol+0x6c>
f0101b08:	80 3a 30             	cmpb   $0x30,(%edx)
f0101b0b:	75 13                	jne    f0101b20 <strtol+0x6c>
f0101b0d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101b11:	75 0d                	jne    f0101b20 <strtol+0x6c>
		s += 2, base = 16;
f0101b13:	83 c2 02             	add    $0x2,%edx
f0101b16:	c7 44 24 1c 10 00 00 	movl   $0x10,0x1c(%esp)
f0101b1d:	00 
f0101b1e:	eb 1c                	jmp    f0101b3c <strtol+0x88>
	else if (base == 0 && s[0] == '0')
f0101b20:	84 c0                	test   %al,%al
f0101b22:	74 18                	je     f0101b3c <strtol+0x88>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101b24:	c7 44 24 1c 0a 00 00 	movl   $0xa,0x1c(%esp)
f0101b2b:	00 
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101b2c:	80 3a 30             	cmpb   $0x30,(%edx)
f0101b2f:	75 0b                	jne    f0101b3c <strtol+0x88>
		s++, base = 8;
f0101b31:	83 c2 01             	add    $0x1,%edx
f0101b34:	c7 44 24 1c 08 00 00 	movl   $0x8,0x1c(%esp)
f0101b3b:	00 
	else if (base == 0)
		base = 10;
f0101b3c:	b8 00 00 00 00       	mov    $0x0,%eax

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101b41:	0f b6 0a             	movzbl (%edx),%ecx
f0101b44:	8d 69 d0             	lea    -0x30(%ecx),%ebp
f0101b47:	89 eb                	mov    %ebp,%ebx
f0101b49:	80 fb 09             	cmp    $0x9,%bl
f0101b4c:	77 08                	ja     f0101b56 <strtol+0xa2>
			dig = *s - '0';
f0101b4e:	0f be c9             	movsbl %cl,%ecx
f0101b51:	83 e9 30             	sub    $0x30,%ecx
f0101b54:	eb 22                	jmp    f0101b78 <strtol+0xc4>
		else if (*s >= 'a' && *s <= 'z')
f0101b56:	8d 69 9f             	lea    -0x61(%ecx),%ebp
f0101b59:	89 eb                	mov    %ebp,%ebx
f0101b5b:	80 fb 19             	cmp    $0x19,%bl
f0101b5e:	77 08                	ja     f0101b68 <strtol+0xb4>
			dig = *s - 'a' + 10;
f0101b60:	0f be c9             	movsbl %cl,%ecx
f0101b63:	83 e9 57             	sub    $0x57,%ecx
f0101b66:	eb 10                	jmp    f0101b78 <strtol+0xc4>
		else if (*s >= 'A' && *s <= 'Z')
f0101b68:	8d 69 bf             	lea    -0x41(%ecx),%ebp
f0101b6b:	89 eb                	mov    %ebp,%ebx
f0101b6d:	80 fb 19             	cmp    $0x19,%bl
f0101b70:	77 18                	ja     f0101b8a <strtol+0xd6>
			dig = *s - 'A' + 10;
f0101b72:	0f be c9             	movsbl %cl,%ecx
f0101b75:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101b78:	3b 4c 24 1c          	cmp    0x1c(%esp),%ecx
f0101b7c:	7d 10                	jge    f0101b8e <strtol+0xda>
			break;
		s++, val = (val * base) + dig;
f0101b7e:	83 c2 01             	add    $0x1,%edx
f0101b81:	0f af 44 24 1c       	imul   0x1c(%esp),%eax
f0101b86:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0101b88:	eb b7                	jmp    f0101b41 <strtol+0x8d>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0101b8a:	89 c1                	mov    %eax,%ecx
f0101b8c:	eb 02                	jmp    f0101b90 <strtol+0xdc>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101b8e:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0101b90:	85 f6                	test   %esi,%esi
f0101b92:	74 02                	je     f0101b96 <strtol+0xe2>
		*endptr = (char *) s;
f0101b94:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0101b96:	89 ca                	mov    %ecx,%edx
f0101b98:	f7 da                	neg    %edx
f0101b9a:	85 ff                	test   %edi,%edi
f0101b9c:	0f 45 c2             	cmovne %edx,%eax
}
f0101b9f:	5b                   	pop    %ebx
f0101ba0:	5e                   	pop    %esi
f0101ba1:	5f                   	pop    %edi
f0101ba2:	5d                   	pop    %ebp
f0101ba3:	c3                   	ret    
	...

f0101bb0 <__udivdi3>:
f0101bb0:	83 ec 1c             	sub    $0x1c,%esp
f0101bb3:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101bb7:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0101bbb:	8b 44 24 20          	mov    0x20(%esp),%eax
f0101bbf:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101bc3:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101bc7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101bcb:	85 ff                	test   %edi,%edi
f0101bcd:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101bd1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101bd5:	89 cd                	mov    %ecx,%ebp
f0101bd7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101bdb:	75 33                	jne    f0101c10 <__udivdi3+0x60>
f0101bdd:	39 f1                	cmp    %esi,%ecx
f0101bdf:	77 57                	ja     f0101c38 <__udivdi3+0x88>
f0101be1:	85 c9                	test   %ecx,%ecx
f0101be3:	75 0b                	jne    f0101bf0 <__udivdi3+0x40>
f0101be5:	b8 01 00 00 00       	mov    $0x1,%eax
f0101bea:	31 d2                	xor    %edx,%edx
f0101bec:	f7 f1                	div    %ecx
f0101bee:	89 c1                	mov    %eax,%ecx
f0101bf0:	89 f0                	mov    %esi,%eax
f0101bf2:	31 d2                	xor    %edx,%edx
f0101bf4:	f7 f1                	div    %ecx
f0101bf6:	89 c6                	mov    %eax,%esi
f0101bf8:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101bfc:	f7 f1                	div    %ecx
f0101bfe:	89 f2                	mov    %esi,%edx
f0101c00:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101c04:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101c08:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101c0c:	83 c4 1c             	add    $0x1c,%esp
f0101c0f:	c3                   	ret    
f0101c10:	31 d2                	xor    %edx,%edx
f0101c12:	31 c0                	xor    %eax,%eax
f0101c14:	39 f7                	cmp    %esi,%edi
f0101c16:	77 e8                	ja     f0101c00 <__udivdi3+0x50>
f0101c18:	0f bd cf             	bsr    %edi,%ecx
f0101c1b:	83 f1 1f             	xor    $0x1f,%ecx
f0101c1e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101c22:	75 2c                	jne    f0101c50 <__udivdi3+0xa0>
f0101c24:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0101c28:	76 04                	jbe    f0101c2e <__udivdi3+0x7e>
f0101c2a:	39 f7                	cmp    %esi,%edi
f0101c2c:	73 d2                	jae    f0101c00 <__udivdi3+0x50>
f0101c2e:	31 d2                	xor    %edx,%edx
f0101c30:	b8 01 00 00 00       	mov    $0x1,%eax
f0101c35:	eb c9                	jmp    f0101c00 <__udivdi3+0x50>
f0101c37:	90                   	nop
f0101c38:	89 f2                	mov    %esi,%edx
f0101c3a:	f7 f1                	div    %ecx
f0101c3c:	31 d2                	xor    %edx,%edx
f0101c3e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101c42:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101c46:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101c4a:	83 c4 1c             	add    $0x1c,%esp
f0101c4d:	c3                   	ret    
f0101c4e:	66 90                	xchg   %ax,%ax
f0101c50:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101c55:	b8 20 00 00 00       	mov    $0x20,%eax
f0101c5a:	89 ea                	mov    %ebp,%edx
f0101c5c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101c60:	d3 e7                	shl    %cl,%edi
f0101c62:	89 c1                	mov    %eax,%ecx
f0101c64:	d3 ea                	shr    %cl,%edx
f0101c66:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101c6b:	09 fa                	or     %edi,%edx
f0101c6d:	89 f7                	mov    %esi,%edi
f0101c6f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101c73:	89 f2                	mov    %esi,%edx
f0101c75:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101c79:	d3 e5                	shl    %cl,%ebp
f0101c7b:	89 c1                	mov    %eax,%ecx
f0101c7d:	d3 ef                	shr    %cl,%edi
f0101c7f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101c84:	d3 e2                	shl    %cl,%edx
f0101c86:	89 c1                	mov    %eax,%ecx
f0101c88:	d3 ee                	shr    %cl,%esi
f0101c8a:	09 d6                	or     %edx,%esi
f0101c8c:	89 fa                	mov    %edi,%edx
f0101c8e:	89 f0                	mov    %esi,%eax
f0101c90:	f7 74 24 0c          	divl   0xc(%esp)
f0101c94:	89 d7                	mov    %edx,%edi
f0101c96:	89 c6                	mov    %eax,%esi
f0101c98:	f7 e5                	mul    %ebp
f0101c9a:	39 d7                	cmp    %edx,%edi
f0101c9c:	72 22                	jb     f0101cc0 <__udivdi3+0x110>
f0101c9e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0101ca2:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101ca7:	d3 e5                	shl    %cl,%ebp
f0101ca9:	39 c5                	cmp    %eax,%ebp
f0101cab:	73 04                	jae    f0101cb1 <__udivdi3+0x101>
f0101cad:	39 d7                	cmp    %edx,%edi
f0101caf:	74 0f                	je     f0101cc0 <__udivdi3+0x110>
f0101cb1:	89 f0                	mov    %esi,%eax
f0101cb3:	31 d2                	xor    %edx,%edx
f0101cb5:	e9 46 ff ff ff       	jmp    f0101c00 <__udivdi3+0x50>
f0101cba:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101cc0:	8d 46 ff             	lea    -0x1(%esi),%eax
f0101cc3:	31 d2                	xor    %edx,%edx
f0101cc5:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101cc9:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101ccd:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101cd1:	83 c4 1c             	add    $0x1c,%esp
f0101cd4:	c3                   	ret    
	...

f0101ce0 <__umoddi3>:
f0101ce0:	83 ec 1c             	sub    $0x1c,%esp
f0101ce3:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101ce7:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0101ceb:	8b 44 24 20          	mov    0x20(%esp),%eax
f0101cef:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101cf3:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101cf7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101cfb:	85 ed                	test   %ebp,%ebp
f0101cfd:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101d01:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101d05:	89 cf                	mov    %ecx,%edi
f0101d07:	89 04 24             	mov    %eax,(%esp)
f0101d0a:	89 f2                	mov    %esi,%edx
f0101d0c:	75 1a                	jne    f0101d28 <__umoddi3+0x48>
f0101d0e:	39 f1                	cmp    %esi,%ecx
f0101d10:	76 4e                	jbe    f0101d60 <__umoddi3+0x80>
f0101d12:	f7 f1                	div    %ecx
f0101d14:	89 d0                	mov    %edx,%eax
f0101d16:	31 d2                	xor    %edx,%edx
f0101d18:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101d1c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101d20:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101d24:	83 c4 1c             	add    $0x1c,%esp
f0101d27:	c3                   	ret    
f0101d28:	39 f5                	cmp    %esi,%ebp
f0101d2a:	77 54                	ja     f0101d80 <__umoddi3+0xa0>
f0101d2c:	0f bd c5             	bsr    %ebp,%eax
f0101d2f:	83 f0 1f             	xor    $0x1f,%eax
f0101d32:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101d36:	75 60                	jne    f0101d98 <__umoddi3+0xb8>
f0101d38:	3b 0c 24             	cmp    (%esp),%ecx
f0101d3b:	0f 87 07 01 00 00    	ja     f0101e48 <__umoddi3+0x168>
f0101d41:	89 f2                	mov    %esi,%edx
f0101d43:	8b 34 24             	mov    (%esp),%esi
f0101d46:	29 ce                	sub    %ecx,%esi
f0101d48:	19 ea                	sbb    %ebp,%edx
f0101d4a:	89 34 24             	mov    %esi,(%esp)
f0101d4d:	8b 04 24             	mov    (%esp),%eax
f0101d50:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101d54:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101d58:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101d5c:	83 c4 1c             	add    $0x1c,%esp
f0101d5f:	c3                   	ret    
f0101d60:	85 c9                	test   %ecx,%ecx
f0101d62:	75 0b                	jne    f0101d6f <__umoddi3+0x8f>
f0101d64:	b8 01 00 00 00       	mov    $0x1,%eax
f0101d69:	31 d2                	xor    %edx,%edx
f0101d6b:	f7 f1                	div    %ecx
f0101d6d:	89 c1                	mov    %eax,%ecx
f0101d6f:	89 f0                	mov    %esi,%eax
f0101d71:	31 d2                	xor    %edx,%edx
f0101d73:	f7 f1                	div    %ecx
f0101d75:	8b 04 24             	mov    (%esp),%eax
f0101d78:	f7 f1                	div    %ecx
f0101d7a:	eb 98                	jmp    f0101d14 <__umoddi3+0x34>
f0101d7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101d80:	89 f2                	mov    %esi,%edx
f0101d82:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101d86:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101d8a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101d8e:	83 c4 1c             	add    $0x1c,%esp
f0101d91:	c3                   	ret    
f0101d92:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101d98:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101d9d:	89 e8                	mov    %ebp,%eax
f0101d9f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0101da4:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0101da8:	89 fa                	mov    %edi,%edx
f0101daa:	d3 e0                	shl    %cl,%eax
f0101dac:	89 e9                	mov    %ebp,%ecx
f0101dae:	d3 ea                	shr    %cl,%edx
f0101db0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101db5:	09 c2                	or     %eax,%edx
f0101db7:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101dbb:	89 14 24             	mov    %edx,(%esp)
f0101dbe:	89 f2                	mov    %esi,%edx
f0101dc0:	d3 e7                	shl    %cl,%edi
f0101dc2:	89 e9                	mov    %ebp,%ecx
f0101dc4:	d3 ea                	shr    %cl,%edx
f0101dc6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101dcb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101dcf:	d3 e6                	shl    %cl,%esi
f0101dd1:	89 e9                	mov    %ebp,%ecx
f0101dd3:	d3 e8                	shr    %cl,%eax
f0101dd5:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101dda:	09 f0                	or     %esi,%eax
f0101ddc:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101de0:	f7 34 24             	divl   (%esp)
f0101de3:	d3 e6                	shl    %cl,%esi
f0101de5:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101de9:	89 d6                	mov    %edx,%esi
f0101deb:	f7 e7                	mul    %edi
f0101ded:	39 d6                	cmp    %edx,%esi
f0101def:	89 c1                	mov    %eax,%ecx
f0101df1:	89 d7                	mov    %edx,%edi
f0101df3:	72 3f                	jb     f0101e34 <__umoddi3+0x154>
f0101df5:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101df9:	72 35                	jb     f0101e30 <__umoddi3+0x150>
f0101dfb:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101dff:	29 c8                	sub    %ecx,%eax
f0101e01:	19 fe                	sbb    %edi,%esi
f0101e03:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101e08:	89 f2                	mov    %esi,%edx
f0101e0a:	d3 e8                	shr    %cl,%eax
f0101e0c:	89 e9                	mov    %ebp,%ecx
f0101e0e:	d3 e2                	shl    %cl,%edx
f0101e10:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101e15:	09 d0                	or     %edx,%eax
f0101e17:	89 f2                	mov    %esi,%edx
f0101e19:	d3 ea                	shr    %cl,%edx
f0101e1b:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101e1f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101e23:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101e27:	83 c4 1c             	add    $0x1c,%esp
f0101e2a:	c3                   	ret    
f0101e2b:	90                   	nop
f0101e2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101e30:	39 d6                	cmp    %edx,%esi
f0101e32:	75 c7                	jne    f0101dfb <__umoddi3+0x11b>
f0101e34:	89 d7                	mov    %edx,%edi
f0101e36:	89 c1                	mov    %eax,%ecx
f0101e38:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0101e3c:	1b 3c 24             	sbb    (%esp),%edi
f0101e3f:	eb ba                	jmp    f0101dfb <__umoddi3+0x11b>
f0101e41:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101e48:	39 f5                	cmp    %esi,%ebp
f0101e4a:	0f 82 f1 fe ff ff    	jb     f0101d41 <__umoddi3+0x61>
f0101e50:	e9 f8 fe ff ff       	jmp    f0101d4d <__umoddi3+0x6d>
