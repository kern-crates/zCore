.equ PHY_MEM_OFS, 0xffffffff00000000
.equ STACK_MAX, 4096 * 16
.equ STACK_MAX_HARTS, 8

	.section .text.entry
	.globl _start
_start:
	#关中断
	csrw sie, zero

	#关闭mmu
	#csrw satp, zero

	#BSS节清零
	la t0, sbss
	la t1, ebss
	bgeu t0, t1, primary_hart

clear_bss_loop:
	# sd: store double word (64 bits)
	sd zero, (t0)
	addi t0, t0, 8
	bltu t0, t1, clear_bss_loop
	
primary_hart:
	call init_vm
	lui t0, %hi(primary_rust_main)
	addi t0, t0, %lo(primary_rust_main)
	jr t0

.globl secondary_hart_start
secondary_hart_start:
	csrw sie, zero
	call init_vm
	lui t0, %hi(secondary_rust_main)
	addi t0, t0, %lo(secondary_rust_main)
	jr t0

init_vm:

	#可清零低12位地址
	lui t0, %hi(boot_page_table_sv39)
	li t1, PHY_MEM_OFS #立即数加载
	#计算出页表的物理地址
	sub t0, t0, t1

	#右移12位，变为satp的PPN
	srli t0, t0, 12

	#satp的MODE设为Sv39
	li t1, 8 << 60

	#写satp
	or t0, t0, t1
	csrw satp, t0

	#刷新TLB
	sfence.vma

	#此时在虚拟内存空间，设置sp为虚拟地址
	li t0, STACK_MAX
	mul t0, t0, a0
	lui sp, %hi(boot_stack_top)
	sub sp, sp, t0
	ret

	.section .data
	.align 12 #12位对齐
boot_page_table_sv39:
	#1G的一个大页: 0x00000000_80000000 --> 0x80000000
	#1G的一个大页: 0xffffffff_80000000 --> 0x80000000

	#前510项置0
	.zero 8
	.zero 8
	.quad (0x80000 << 10) | 0xef #0x80000000 --> 0x80000000

	.zero 8 * 507
	#倒数第二项，PPN=0x80000(当转换为物理地址时还需左移12位), 标志位DAG_XWRV置1
	.quad (0x80000 << 10) | 0xef
	.zero 8

	.section .bss.stack
	.align 12
	.global boot_stack
boot_stack:
	.space STACK_MAX * STACK_MAX_HARTS
	.global boot_stack_top
boot_stack_top:
