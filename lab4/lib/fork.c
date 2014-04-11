// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;

	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
//------------  Lab4  ----------------------------------------------------------------------------------------		
	if ((err & FEC_WR) == 0) 
		panic("pgfault: not a write!\n");
	uintptr_t ad = (uintptr_t) addr;
	if ( (uvpt[ad / PGSIZE] & PTE_COW) && (uvpd[PDX(addr)] & PTE_P) ) {
		r = sys_page_alloc(0, (void *)PFTEMP, PTE_P | PTE_U | PTE_W);
		if (r < 0)
			panic("sys_page_alloc failed in pgfault %e\n", r);
		
		addr = ROUNDDOWN(addr, PGSIZE);
		memcpy(PFTEMP, addr, PGSIZE);

		r = sys_page_map(0, (void *)PFTEMP, 0, addr, PTE_P | PTE_W | PTE_U);
		if (r < 0)
			panic("sys_page_map failed in pgfault %e\n", r);

		return;
	}
	else {
		panic("pgfault: not a copy-on-write!\n");
	}
//------------  Lab4  ----------------------------------------------------------------------------------------			

	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.
	//   No need to explicitly delete the old page's mapping.

	// LAB 4: Your code here.
//------------  Lab4  ----------------------------------------------------------------------------------------		

//------------  Lab4  ----------------------------------------------------------------------------------------			
	//panic("pgfault not implemented");
}

//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
	int r;

	// LAB 4: Your code here.
//------------  Lab4  ----------------------------------------------------------------------------------------		
	if (pn * PGSIZE == UXSTACKTOP - PGSIZE) return 0;

	uintptr_t addr = (uintptr_t)(pn * PGSIZE);
	if ( (uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW) ) {
		r = sys_page_map(0, (void *)addr, envid, (void *)addr, PTE_P | PTE_U | PTE_COW);
		if (r < 0)
			panic("sys_page_map failed in duppage %e\n", r);

		r = sys_page_map(0, (void *)addr, 0, (void *)addr, PTE_P | PTE_U | PTE_COW);
		if (r < 0)
			panic("sys_page_map failed in duppage %e\n", r);
	}
	else {
		r = sys_page_map(0, (void *)addr, envid, (void *)addr, PTE_P | PTE_U);
		if (r < 0)
			panic("sys_page_map failed in duppage %e\n", r);
	}
	return 0;
//------------  Lab4  ----------------------------------------------------------------------------------------			
	//panic("duppage not implemented");
	return 0;
}

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use uvpd, uvpt, and duppage.
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
	// LAB 4: Your code here.
//------------  Lab4  ----------------------------------------------------------------------------------------		
	set_pgfault_handler(pgfault);
	envid_t pid = sys_exofork();
	//cprintf("pid: %x\n", pid);
	if (pid < 0)
		panic("sys_exofork failed in fork %e\n", pid);
	//cprintf("fork point2!\n");
	if (pid == 0) {
		//cprintf("child forked!\n");
		thisenv = &envs[ENVX(sys_getenvid())];
		//cprintf("child fork ok!\n");
		return 0;
	}
	uint32_t i;
	for (i = 0; i < UTOP; i += PGSIZE){
		if ( (uvpd[PDX(i)] & PTE_P) && (uvpt[i / PGSIZE] & PTE_P) && (uvpt[i / PGSIZE] & PTE_U) )
			duppage(pid, i / PGSIZE);
	}

	int res;
	res = sys_page_alloc(pid, (void *)(UXSTACKTOP - PGSIZE), PTE_U | PTE_W | PTE_P);
	if (res < 0)
		panic("sys_page_alloc failed in fork %e\n", res);

	extern void _pgfault_upcall(void);
	res = sys_env_set_pgfault_upcall(pid, _pgfault_upcall);
	if (res < 0)
		panic("sys_env_set_pgfault_upcall failed in fork %e\n", res);

	res = sys_env_set_status(pid, ENV_RUNNABLE);
	if (res < 0)
		panic("sys_env_set_status failed in fork %e\n", res);

	return pid;
//------------  Lab4  ----------------------------------------------------------------------------------------			
	//panic("fork not implemented");
}

// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}
