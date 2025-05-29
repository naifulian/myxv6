# 为每个 hart 设置 4KB 的栈，然后跳转到 start 函数
.section .text
.global _entry
_entry:
        # sp = stack0 + (hartid * 4096)
        la sp, stack0       # 加载 stack0 的地址到栈指针寄存器 sp
        li a0, 1024*4       # 加载常量到寄存器
        csrr a1, mhartid    # 读取当前硬件线程 id

        addi a1, a1, 1      # a1 = hartid + 1
        mul a0, a0, a1      # a0 = (1024 * 4) * (hartid  + 1)
        add sp, sp, a0      # sp = stack0 + a0
        # 跳转到 start.c 的 start 函数
        call start
# 如果 start 函数返回了则进行死循环
spin:
        j spin
