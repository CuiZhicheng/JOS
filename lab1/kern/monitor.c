// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>

#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>

#define CMDBUF_SIZE	80	// enough for one VGA text line


struct Command {
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};

static struct Command commands[] = {
	{ "help", "Display this list of commands", mon_help },
	{ "kerninfo", "Display information about the kernel", mon_kerninfo },
	{ "backtrace", "Display the backtrace", mon_backtrace},
	{ "setcolor", "Show the string in set color, use help without arguments",mon_setcolor},
};
#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	uint32_t* ebp = (uint32_t*) read_ebp();
	cprintf("Stack backtrace:\n");
	while (ebp != 0) {
	    cprintf("  ebp %08x  eip %08x", ebp, *(ebp+1));
	    cprintf("  args %08x %08x %08x %08x %08x\n", *(ebp+2), *(ebp+3), *(ebp+4), *(ebp+5), *(ebp+6));
	    struct Eipdebuginfo info;
	    debuginfo_eip(*(ebp+1), &info);
	    cprintf("         %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, 							 info.eip_fn_name, *(ebp + 1) - info.eip_fn_addr);
   	    ebp = (uint32_t*) *ebp;
	}
	return 0;
}

int
mon_setcolor(int argc, char **argv, struct Trapframe *tf)
{
 	if(argc != 3)
	{
		cprintf("     Choose the color you like.\n");
		cprintf("     The color board:\n");
		cprintf("     Background Color|Foreground Color\n");
		cprintf("      I | R | G | B | | I | R | G | B\n"); 
	 	cprintf("     Your input should be: setcolor [8-bit binary number] [a string you want to output]\n");
		cprintf("     Example:setcolor 10000001 Example\n");
		return 0;
	}
	int tempcolor = 0;
	int i=0;
	for(i = 0; i < 8; i++)
	{
		tempcolor = tempcolor * 2 + argv[1][i] - '0';
	}
	tempcolor = tempcolor << 8;
	int c;
	for(i = 0; argv[2][i] != '\0'; i++)
	{
		c = (int)argv[2][i];
		c = c | tempcolor;
		cprintf("%c",c);
	}
	cprintf("\n");
	return 0;
}



/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void
monitor(struct Trapframe *tf)
{
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");
	
	//int x = 1, y = 3, z = 4;
	//cprintf("x %d, y %x, z %d\n", x, y, z);

	//unsigned int i = 0x00646c72;
        //cprintf("H%x Wo%s", 57616, &i);
	//cprintf("x=%d y=%d", 3);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}