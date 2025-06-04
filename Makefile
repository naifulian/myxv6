# 避免 target kernel 被当作目录名导致 make 不进行编译  
.PHONY: qemu qemu-gdb clean kernel

# 内核目录
K = kernel

# 交叉编译工具链 
CC = riscv64-unknown-elf-gcc
QEMU = qemu-system-riscv64
GDB = riscv64-unknown-elf-gdb

# qemu 模拟的计算机 CPU 的核心数
CPUS = 3

# 编译选项
CFLAGS = -Wall -Werror -O0
CFLAGS += -fno-omit-frame-pointer -ggdb
CFLAGS += -MD -mcmodel=medany
CFLAGS += -ffreestanding -fno-common -nostdlib
CFLAGS += -mno-relax
CFLAGS += -fno-stack-protector -fno-pie -no-pie
CFLAGS += -z max-page-size=4096
# -Wall 打开所有警告
# -Werror将所有警告认为是错误
# -O0不进行编译器优化
# -fno-omit-frame-pointer生成栈帧的相关信息
# -ggdb生成调试信息
# -MD生成独立的.d文件，.d包含依赖文件
# -mcmodel=medany针对riscv构架的代码模型
# -ffreestanding-fno-common-nostdlib-mno-relax不使用标准C库
# -ffreestanding:生成独立运行的代码，即代码不依赖于标准库或操作系统提供的额外支持。通常用于裸机嵌入式系统或操作系统内核的开发
# -fno-common:禁止编译器将未初始化的全局变量和函数定义放置在公共（common）段中。为了避免因为全局变量在多个源文件中重复定义而导致链接错误。
# -nostdlib:不链接标准C库
# -mno-relax:不要使用指合重定位优化。在链接阶段可能会进行指合重定位，但该选项可以避免这种情况，确保代码的准确性
# -fno-stack-protector不使用栈溢出保护机制
# -fno-pie-no-pie不生成pie
# -z max-page-size=4096 配置页大小

# 启动 qemu 需要的参数
QEMUOPTS = -machine virt -bios none -kernel $(K)/kernel.elf -m 128M -smp $(CPUS) -nographic
# -machine virt 指定 qemu 模拟的硬件平台为 RISCV VirtIO 机器，virt 是一个通用的 RISCV 平台
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

# 启动 qemu
qemu: kernel
	$(QEMU) $(QEMUOPTS)

# 默认
qemu-gdb: kernel
	@echo "现在在另一个终端中启用 GDB"
	@$(QEMU) $(QEMUOPTS) -s -S
	

# 清理中间文件
clean:
	rm -f $(K)/kernel.elf $(K)/kernel.d