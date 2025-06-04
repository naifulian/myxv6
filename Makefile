# 声明伪目标，避免 target 与同名文件或文件夹重名导致 make 不工作
.PHONY: qemu qemu-gdb clean kernel

# 内核目录
K = kernel

# 工具链 
CC = riscv64-unknown-elf-gcc 		# RISCV 交叉编译器
QEMU = qemu-system-riscv64			# qemu 模拟器
GDB = riscv64-unknown-elf-gdb 		# RISCV 使用的 GDB

# qemu 模拟的计算机 CPU 的核心数
CPUS = 3

# 编译选项
CFLAGS = -Wall -Werror -O0 							# 启用所有警告，视警告为编译错误，禁用优化
CFLAGS += -fno-omit-frame-pointer -ggdb 			# 强制保留栈帧指针，生成 GBD 专用的调试信息
CFLAGS += -MD 										# 自动生成 .d 依赖文件，当 entry.S 或 start.c 被修改时，make 能感知到并重新编译
CFLAGS += -mcmodel=medany 							# 使用中等代码模型，允许代码和静态数据位于任意 32 位地址开始(0x80000000)
CFLAGS += -ffreestanding 							# 编译独立环境程序（不依赖操作系统或标准库）。
CFLAGS += -fno-common 			 					# 禁止未初始化全局变量放在 COMMON 段,强制显式定义全局变量,避免多个文件定义同名变量导致链接冲突
CFLAGS += -nostdlib									# 不链接标准库
CFLAGS += -mno-relax 								# 禁用链接器松弛优化，RISC-V 的 auipc/jalr 等指令可能被优化为 jal，避免因优化导致引导代码失效（如 OpenSBI 跳转地址错误）。
CFLAGS += -fno-stack-protector -fno-pie -no-pie 	# 禁用栈溢出保护，禁用位置无关可执行文件
CFLAGS += -z max-page-size=4096 					# 设置内存页大小为 4KB


# qemu 的启动参数
QEMUOPTS = -machine virt -bios none -kernel $(K)/kernel.elf -m 128M -smp $(CPUS) -nographic
# -machine virt 指定 qemu 模拟的硬件平台为 RISCV VirtIO，virt 是一个通用的 RISCV 平台
# -bios none 不加载 BIOS 或 bootloader，直接从内核启动
# -kernel $(K)/kernel.elf 指定要运行的内核镜像文件，qemu 会将其加载到内存 0x80000000 出执行
# -m 128M 设置虚拟机的内存大小为 128MB
# -smp $(CPUS) 设置虚拟机的 CPU 核心数
# -nographic 禁用图形界面，所有输出通过终端显示


# 编译出 kernel.elf 文件
kernel:
	$(CC) $(CFLAGS) \
	$(K)/entry.S \
	$(K)/start.c \
	-T $(K)/kernel.ld \
	-o $(K)/kernel.elf

# 启动 qemu 然后直接运行
qemu: kernel
	$(QEMU) $(QEMUOPTS)


# 清理编译产物
clean:
	rm -f $(K)/kernel.elf $(K)/kernel.d