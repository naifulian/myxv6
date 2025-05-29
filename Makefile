# 声明伪目标，告诉 make 这些目标不是文件，
# 如果目标是个文件且文件存在，没有变化，make 就不会执行后面的命令
.PHONY: kernel clean qemu qemu-gdb

# 定义变量：kernel，内核目录（保持你的原始命名）
K := kernel

# 定义编译后的目标文件（保持简单，后续可以自动收集）
OBJS = $(K)/entry.o $(K)/start.o

# 最终链接生成的 ELF 文件名
KERNEL_ELF = kernel.elf


# 使用 qemu 的系统模拟一台 riscv64 的硬件
QEMU = qemu-system-riscv64

# RISC-V 交叉调试
GDB = riscv64-unknown-elf-gdb

# RISC-V 交叉编译
CC = riscv64-unknown-elf-gcc

# RISC-V 交叉链接
LD = riscv64-unknown-elf-ld

# 反汇编工具
OBJDUMP = riscv64-unknown-elf-objdump


# GCC 编译参数
CFLAGS = -Wall -Werror              # 打开所有警告并把警告当错误
CFLAGS += -O                        # 打开基本优化
CFLAGS += -fno-omit-frame-pointer   # 不省略帧指针（便于调试栈帧）
CFLAGS += -ggdb -gdwarf-2           # 生成 GDB 所需调试信息
CFLAGS += -MD                       # 生成依赖文件（.d）
CFLAGS += -mcmodel=medany           # 中等地址模型，适合 RISC-V kernel
CFLAGS += -fno-common -nostdlib     # 禁止多个全局变量重复定义，不链接标准库
CFLAGS += -I$(K)                    # 添加内核目录到头文件搜索路径

# 链接选项
LDFLAGS = -T $(K)/kernel.ld -nostdlib

# 启动 qemu 的参数
QEMUOPTS = 	-machine virt  			# virt 虚拟机
QEMUOPTS += -bios none   		   	# 不使用 bios
QEMUOPTS += -kernel $(KERNEL_ELF)   # 加载编译好的 kernel
QEMUOPTS += -m 128M                 # 分配 128MB 内存
QEMUOPTS += -smp 4                 	# 模拟 4 核
QEMUOPTS += -nographic             	# 禁止图形界面，在终端运行


# 默认目标：构建内核,链接所有的 .o 文件，生成 kernel.elf，
# 然后将对 kernel.elf 反汇编得到的结果重定向到到 kernel.asm
$(KERNEL_ELF): $(OBJS) $(K)/kernel.ld
	$(LD) $(LDFLAGS) -o $@ $(OBJS)
	$(OBJDUMP) -S $@ > $(K)/kernel.asm

# 把 kernel 目标指向 kernel.elf 文件，方便写命令时输入短名字
kernel: $(KERNEL_ELF)

# 编译汇编文件（.S）为目标文件（.o）
$(K)/%.o: $(K)/%.S
	$(CC) $(CFLAGS) -c $< -o $@

# 编译 C 源文件为 .o 文件（注意路径和 %.o 匹配）
$(K)/%.o: $(K)/%.c
	$(CC) $(CFLAGS) -c $< -o $@


# 启动 QEMU 模拟器来运行内核
qemu: kernel
	$(QEMU) $(QEMUOPTS)




# 清理所有编译生成的文件
clean:
	rm -f $(KERNEL_ELF) $(K)/kernel.asm $(K)/*.o $(K)/*.d .gdbinit

# 自动包含头文件依赖，这样源代码里加头文件会自动追踪变化
-include $(OBJS:.o=.d)

help:
	@echo "  make kernel  	- 编译内核"
	@echo "  make qemu    	- 运行QEMU"
	@echo "  make qemu-gdb 	- 启动调试"
	@echo "  make clean   	- 清理构建文件"