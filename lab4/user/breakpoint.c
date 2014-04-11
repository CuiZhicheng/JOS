// program to cause a breakpoint trap

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
	asm volatile("int $3");
	asm volatile("movl $0x1, %ebx");
	asm volatile("movl $0x2, %ebx");
	asm volatile("movl $0x3, %ebx");
	cprintf("test1\n");
	cprintf("test2\n");
	cprintf("test3\n");
}

