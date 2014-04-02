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
#include <kern/env.h>
//<<<<<<< HEAD
#include <kern/trap.h>
//=======
#include <kern/pmap.h>
//>>>>>>> lab2

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
	{ "showmappings", "Display all of the physical page mappings that apply to a particular range of virtual/linear addresses in the currently active address space.", mon_showmappings},
	{ "setperm", "Explicitly set, clear, or change the permissions of any mapping in the current address space.", mon_setperm},
	{ "dump", "Dump the contents of a range of memory given either a virtual or physical address range.", mon_dump},
	{ "c", "Continue execution from the current location", mon_c},
	{ "si", "Single-step one instruction at a time", mon_si},
};
#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

/***** Implementations of basic kernel monitor commands *****/

//----------------------------------------My Code-------------------------------------------------------------
uint32_t myxtou_lab2(char *buf) 	//transfer address to number
{
	uint32_t r = 0;
	buf += 2;		//buf = "0x....."
	while (*buf)	{
		r = r * 16;
		if (*buf >= 'a') 
			r = r + *buf - 'a' + 10;			//a...f
		else 
			r += *buf - 48;					//0...9
		buf++;
	}
	return r;
}

void myprint_lab2(pte_t *pte)		//print the permission bits
{
	cprintf("PTE_P: %x, PTE_W: %x, PTE_U: %x\n", *pte & PTE_P, (*pte & PTE_W) >> 1, (*pte & PTE_U) >> 2);
}

bool check_pa_lab2(uint32_t pa, uint32_t *result)		//infomation from pmap.c/mem_int
{
	if (pa >= PADDR(pages) && pa < PADDR(pages) + PTSIZE)	{
		*result = *(uint32_t *)(pa - PADDR(pages) + UPAGES);
		return true;
	}
	if (pa >= PADDR(bootstack) && pa < PADDR(bootstack) + KSTKSIZE)	{
		*result = *(uint32_t *)(pa - PADDR(bootstack) + KSTACKTOP - KSTKSIZE);
		return true;
	}
	if (pa >= 0 && pa < 0 - KERNBASE)	{
		*result = *(uint32_t *)(pa + KERNBASE);
		return true;
	}
	return false;
}

//----------------------------------------My Code-------------------------------------------------------------

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

int
mon_showmappings(int argc, char **argv, struct Trapframe *tf)
{
	pte_t *pte;
	if (argc != 3) {
	        cprintf("Your input should be: showmappings begin_addr(0x...) end_addr(0x...)\n");
		return 0;
	}
	uint32_t left = myxtou_lab2(argv[1]);				//begin address
	uint32_t right = myxtou_lab2(argv[2]);				//end address
	cprintf("left: %x  right: %x\n", left, right);
	if (left > right)						//check
	{
		cprintf("Wrong Input! Your begin_addr should be less than end_addr!\n");
		return 0;
	}
	for (; left <= right; left += PGSIZE)				//display the mapping page by page
	{
		pte = pgdir_walk(kern_pgdir, (void*)left, true);
		if (!pte || ((*pte & PTE_P) == 0))
		{
			cprintf("page not exist: %x\n", left);
		}
		else
		{
			cprintf("page %x mapped to 0x%08x with permission: ", left, PTE_ADDR(*pte));
			myprint_lab2(pte);
		}		
	}
	return 0;
}

int 
mon_setperm(int argc, char **argv, struct Trapframe *tf)
{
	if (argc != 6) {
		cprintf("Your input should be: setperm addr(0x...) [0|1](clear or set) [0|1](P) [0|1](W) [0|1](U)\n");
		return 0;
	}
	uint32_t addr = myxtou_lab2(argv[1]);			//address
	pte_t *pte;
	pte = pgdir_walk(kern_pgdir, (void*)addr, true);	//find pte
	cprintf("Address: 0x%08x\n", addr);
	cprintf("Old Permission: ");
	myprint_lab2(pte);					//print permission
	uint32_t perm = 0;
	if (argv[3][0] == '1') perm |= PTE_P;			
	if (argv[4][0] == '1') perm |= PTE_W;
	if (argv[5][0] == '1') perm |= PTE_U;
	if (argv[2][0] == '0') *pte = *pte & ~perm;		//change permission
	else *pte = PTE_ADDR(*pte) | perm;
	cprintf("New Permission: ");
	myprint_lab2(pte);					//print new permission
	return 0;
}

int 
mon_dump(int argc, char **argv, struct Trapframe *tf) {
	if (argc != 4) {
		cprintf("Yout input should be: dump [v|p](virtual or physical) begin_addr(0x...) length(0x...)\n");
		return 0;
	}
	uint32_t addr = myxtou_lab2(argv[2]);
	uint32_t len = myxtou_lab2(argv[3]);
	pte_t *pte;
	addr = ROUNDDOWN(addr, 4);
	if (argv[1][0] == 'v') {			//virtual memory just show the content
		int i;
		for (i = 0; i < len; i++){
			if (i % 4 == 0) cprintf("virtual memory %08x: ", addr + 4 * i);
			pte = pgdir_walk(kern_pgdir, (void*)ROUNDDOWN(addr + i * 4, PGSIZE), 0);
			if (pte && (*pte & PTE_P))
				cprintf("0x%08x ", *(uint32_t *)(addr + 4 * i));
			else cprintf("-------- ");
			if (i % 4 == 3) cprintf("\n");
		}
	}
	if (argv[1][0] == 'p') {			//physical memory, first check the address
		int i;					//then show the content
		uint32_t result;
		for (i = 0; i < len; i++){
			if (i % 4 == 0) cprintf("physical memory %08x: ", addr + 4 * i);
			if (check_pa_lab2(addr + i * 4, &result))	//my function to check the address
				cprintf("0x%08x ", result);
			else
				cprintf("-------- ");
			if (i % 4 == 3) cprintf("\n");
		}
	}
	return 0;
}

int 
mon_c(int argc, char **argv, struct Trapframe *tf) {
	if (tf == NULL){
		cprintf("Continue Error!\n");
		return -1;
	}

	tf->tf_eflags &= (~FL_TF);
	env_run(curenv);
	cprintf("This should never be printed!\n");
	return 0;
}

int mon_si(int argc, char **argv, struct Trapframe *tf) {
	if (tf == NULL){
		cprintf("Continue Error!\n");
		return -1;
	}

	tf->tf_eflags |= FL_TF;
	env_run(curenv);
	cprintf("This should never be printed!\n");
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
//<<<<<<< HEAD

	if (tf != NULL)
		print_trapframe(tf);

//=======
	
//>>>>>>> lab2
	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}

void
my_monitor(struct Trapframe *tf)
{
	char *buf;

	cprintf("This is for DEBUG!\n");
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");
//<<<<<<< HEAD

	if (tf != NULL)
		print_trapframe(tf);

//=======
	
//>>>>>>> lab2
	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}