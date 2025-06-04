本项目仿照 xv6，从头开始一步步完成操作系统的编写
1. begin：
    - 体验裸机开发，在 qemu 中运行不依赖于任何标准库，操作系统的裸机程序
    - 使用 gdb 进行 debug

# begin：从汇编跳转到 C

在 qemukernel.elf，该程序不依赖于任何标准库和操作系统，直接运行在 qemu 模拟出来的计算机系统中，没有实现自己的 printf，后面会使用串口实现打印

- entry.S：为每个核心设置好栈，跳转到 start 函数
- start.c：死循环，什么也不做
- kernel.ld：控制内核代码和数据在内存中的布局，确保内核能能在硬件上正确启动和运行
- Makefile：项目构建

## qemu 模拟器

qemu 是一个可以模拟计算机硬件的程序，有两种模拟方式：
1. 用户模式模拟（User-mode emulation）：只模拟用户空间程序，将针对特定架构的指令翻译为主机指令
2. ​系统模式模拟（System-mode emulation）：模拟完整的计算机系统
，包括CPU、内存、设备等所有硬件

使用系统模式模拟一个 RISCV 架构计算机，然后编写操作系统代码，在开发机编译代码，然后在 qemu 模拟出的计算机上运行操纵系统

## ISA

ISA 是操作系统和硬件的桥梁，


## 交叉编译

在编写用户程序的时候，比如说一个 hello world 程序，从编写程序源码，编译程序到运行程序都在一台计算机上进行，即开发程序的计算机和运行程序的计算机是同一台计算机，而这台计算机大概率是基于 x86 架构的

我们要开发的 RISCV 的操作系统需要运行在 RISCV 架构的计算机上，即在开发机(本地机器)上进行开发操作系统，然后在 qemu 模拟的 RISCV 计算机上运行操作系统

要想在 x86 架构的开发机上编译出可以在 RISCV 架构上运行的程序，就需要使用交叉编译工具链：
- riscv64-unknown-elf-gcc：编译出 RISCV 架构的代码的交叉编译器
- riscv64-unknown-elf-ld：链接器
- riscv64-unknown-elf-objdump：反汇编工具
- riscv64-unknown-elf-gdb：调试器

## 裸机程序

和应用程序的开发不同，裸机程序直接在硬件上运行、不依赖操作系统或其他软件层的程序。它直接与硬件交互，没有操作系统提供的抽象：文件系统、进程管理、设备驱动、虚拟化等

qemu 模拟出来的计算机没有操作系统

## ELF 格式

现代通用计算机绝大多数都是采用冯诺依曼架构，程序的指令和数据都存储在内存中，而 ELF(Executable and Linkable Format) ，是 Unix/Linux 系统下可执行文件、目标文件和共享库的标准格式。xv6-riscv 也使用 ELF 格式来组织内核和用户程序

编译器将程序编译为 ELF 格式，操作系统负责加载到内存中，ELF 相当于编译器和操作系统之间的约定，不同的操作系统可能使用不同的可执行程序格式，比如 windows 使用 PE 格式，Unix/linux 使用 ELF 格式，不同格式的可执行程序在不同的操作系统的计算机上就无法执行

ELF 文件的基本结构：
- ELF 头(ELF Header)：描述文件的基本属性
- 程序头表(Program Header Table)：描述段(Segment)信息，用于加载执行
- 各种段
    - .text
    - .data
    - 
- 节头表 (Section Header Table)：描述节(Section)信息，用于链接和调试

## 启动 qemu



### 链接器脚本


### 汇编与 C



## 使用 gdb 进行调试

需要安装 riscv64-unknown-elf-gdb

在 makefile 中增加 target：qemu-gdb，然后在 qemu 启动的时候指定 GDB 服务器的端口，-s 参数默认使用 1234 端口，也可以使用 -gdb tcp::port 指定

然后 -S 参数让 qemu 启动的时候就暂停下来，等待 gdb 的命令，这样可以调试 qemu 启动到内核加载这段时间的代码，否则会直接跳到内核加载完成后的 start 函数处调试


