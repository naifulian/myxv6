本项目仿照 xv6，从头开始一步步完成操作系统的编写
# 分支
## begin：

本阶段的目标是编写一个最小可运行的操作系统内核，可以在 RISC-V 架构下的 QEMU 模拟器中运行。整个过程完全不依赖标准库和已有操作系统，属于裸机开发（bare-metal development）的范畴。

但由于我们不能使用标准库提供的 printf 函数，所以在这里只是做一个死循环，之后会初始化串口，使用串口打印 hello world

**本阶段的主要任务**：
- 编写 entry.S：为每个 hart 设置 4KB 大小的栈，然后跳转到 start 函数
- 编写 start.c：定义 stack0 数组，作为栈的空间，然后在 start 函数内死循环
- 使用链接器脚本控制 ELF 格式的内核可执行程序在内存中的布局
- 编写 Makefile 构建项目

**需要掌握的知识**
1. ISA：了解 ISA 是什么
2. RISC-V
    - RISC-V 汇编
    - RISC-V 特权级机制
    - RISC-V 执行环境标准
3. 编译系统：了解程序是如何经过编译系统变为可执行程序的
4. ELF：了解 ELF 可执行文件格式
5. 交叉编译和裸机开发
6. C 和汇编的协同：编写操作系统的代码主要使用 C 语言，但由于操作系统的开发属于裸机开发，没有运行时库和可用的操作系统为 C 语言初始化执行环境，所以需要掌握如何使用汇编为 C 语言的执行提供环境
7. qemu 模拟器：QEMU 是一种强大的虚拟化/仿真平台，既可以选择用户模式模拟又可以选择模拟多个架构下的完整系统。此项目中，使用 QEMU 的系统模式（system-mode）模拟一台 RISC-V 架构计算机，运行我们编写的裸机程序。你需要了解以下关于 qemu 的知识点
- qemu 启动参数的配置
- 了解 qemu 的启动流程
- 了解 qemu 的 gdbserver

**需要学会的工具**：
1. git 的基本使用
2. makefile 的编写
3. 链接器脚本的编写
4. gdb 调试
5. 配置 vscode 调试 


# begin：从汇编跳转到 C

## ISA

ISA（Instruction Set Architecture）是连接软件与硬件的接口，它定义了一台 CPU 能做什么事，也就是：
- 支持哪些指令（如加法、内存访问、跳转等）；
- 有多少寄存器、寄存器的作用和名称；
- 内存地址如何编码；
- 系统调用、异常、特权级等行为如何实现。

从软件角度看，ISA 是程序员和编译器面对的“机器”；从硬件角度看，ISA 是 CPU 实现时必须遵循的功能规范。

目前有两类主流 ISA：
- 复杂指令集(CISC)：以 x86 架构为代表，特点是每条指令功能复杂，指令长度不固定，硬件解码开销大，但相应的最后编写的程序比较短。x86 指令集的历史比较悠久，相应的历史包袱也比较大
- 精简指令集(RISC)：以 RISC-V 和 ARM 架构为代表，特点是每条指令执行一个简单操作，固定长度，利于并行、硬件设计简单

xv6 操作系统最早基于 x86 架构(xv6-public)，但目前已经停止维护。现在 xv6 是基于 RISC-V 指令集架构的(xv6-riscv)。RISC-V 指令集架构具有开源、模块化、简洁、适合教学和研究的优点。

## RISC-V

RISC-V 是一个开源的指令集架构（ISA），由加州大学伯克利分校于 2010 年推出。它具备以下特点：
- 精简统一的指令格式：每条指令长度固定为 32 位，易于解码与流水线处理；
- 模块化设计：基础指令集（RV32I/RV64I）可选配扩展（如 M-整数乘除、F-浮点、S-虚拟内存等）；
- 开源：无需授权费用，适合教学、科研和商业用途；
- 支持多种特权级别：为操作系统设计提供了良好的隔离机制。


## RISC-V 汇编

目前虽然操作系统的编写大部分是由高级语言编写，但还是有必要了解汇编语言。RISC-V 汇编相较于 x86 更加简洁

### 通用寄存器

RISC-V 提供了 32 个通用寄存器，每个寄存器都有 ABI 别名和约定好的用途
| 寄存器   | ABI 名称      | 描述                         |
|----------|--------------|-----------------------------|
| x0       | zero         | 硬连线为 0                   |
| x1       | ra           | 返回地址                     |
| x2       | sp           | 栈指针                       |
| x3       | gp           | 全局指针                     |
| x4       | tp           | 线程指针                     |
| x5       | t0           | 临时寄存器/备用链接寄存器     |
| x6-7     | t1-2         | 临时寄存器                   |
| x8       | s0/fp        | 保存寄存器/帧指针            |
| x9       | s1           | 保存寄存器                   |
| x10-11   | a0-1         | 函数参数/返回值              |
| x12-17   | a2-7         | 函数参数                     |
| x18-27   | s2-11        | 保存寄存器                   |
| x28-31   | t3-6         | 临时寄存器                   |
| f0-7     | ft0-7        | 浮点临时寄存器               |
| f8-9     | fs0-1        | 浮点保存寄存器               |
| f10-11   | fa0-1        | 浮点参数/返回值              |
| f12-17   | fa2-7        | 浮点参数                     |
| f18-27   | fs2-11       | 浮点保存寄存器               |
| f28-31   | ft8-11       | 浮点临时寄存器               |

### CSR 寄存器

CSR 寄存器又叫做控制和状态寄存器(Control and Status Registers)，用于控制 CPU 的运行状态，主要用于管理：
- 中断使能与处理
- 特权级状态切换
- 时钟、性能计数器
- Trap（异常/中断）入口地址等

**用户模式 CSR**
| CSR地址 | 寄存器名 | 权限  | 关键作用描述         |
|---------|----------|------|--------------------|
| 0x000   | ustatus  | URW  | 用户态状态寄存器     |
| 0x005   | utvec    | URW  | 用户态陷阱向量       |

**机器模式 CSR**

| CSR地址 | 寄存器名 | 权限 | 关键作用描述         |
|---------|----------|------|--------------------|
| 0x300   | mstatus  | MRW  | 全局状态控制寄存器  |
| 0x305   | mtvec    | MRW  | 陷阱处理入口地址    |
| 0x341   | mepc     | MRW  | 异常返回地址        |
| 0x342   | mcause   | MRO  | 异常原因码          |
| 0x343   | mtval    | MRO  | 异常附加信息        |
| 0x304   | mie      | MRW  | 中断使能控制        |
| 0x344   | mip      | MRO  | 中断等待状态        |

**监督者模式 CSR**
| CSR地址 | 寄存器名 | 权限 | 关键作用描述                     |
|---------|----------|------|----------------------------------|
| 0x100   | sstatus  | SRW  | 监管者状态寄存器                 |
| 0x104   | sie      | SRW  | 监管者中断使能                   |
| 0x105   | stvec    | SRW  | 监管者陷阱向量                   |
| 0x140   | sscratch | SRW  | 临时数据存储                     |
| 0x141   | sepc     | SRW  | 监管者异常PC                     |
| 0x142   | scause   | SRW  | 监管者异常原因                   |
| 0x143   | stval    | SRW  | 监管者异常附加值                 |
| 0x144   | sip      | SRW  | 监管者中断等待                   |
| 0x180   | satp     | SRW  | 页表基址寄存器                   |

**陷阱处理相关 CSR**
| CSR地址（十六进制） | 寄存器名    | 权限 | 描述                          |
|---------------------|-------------|------|-------------------------------|
| 0x341               | `mepc`      | MRW  | 异常发生时的PC值              |
| 0x342               | `mcause`    | MRW  | 异常/中断原因代码             |
| 0x343               | `mtval`     | MRW  | 异常附加信息（如非法地址）    |


### 普通指令

// TODO

### 特权级指令

// TODO

## RISCV 特权级机制

现代处理器一般都有多个特权级模式，一个 RISCV 处理器可以有以下特权级模式，任何时候一个 RISCV 硬件线程都是运行在某个特权级之上的
- User Mode
- Supervisor Mode
- Hypervisor Mode
- Machine Mode

x86 使用的固定特权级(Ring 0-3)，相比 RISCV 使用的分层特权级，设计复杂且历史包袱重，需要考虑兼容性等问题

RISCV 的分层特权级主要有这两点好处：
1. 更加安全：RISCV 特权级的权限规则直接由硬件电路实现，确保了软件行为(比如恶意代码或配置错误)无法绕过权限边界，从根源上消除了 x86 因软硬件耦合导致的权限楼顶 
2. 灵活的层级配置：可以根据应用场景选择需要的特权级，支持从嵌入式设备(仅使用 M-mode)到云服务器(使用所有的四种模式)的灵活配置

## 不同特权级下的执行环境和接口规范

1. 应用执行环境(Application Execution Environment, AEE)
    - 定义：AEE 是用户态应用程序的运行环境，由操作系统内核提供支持。
    - 特征：可以使用非特权指令，不能直接访问硬件或特权寄存器，依赖操作系统提供服务
    - 组成：用户程序，运行时库，ABI 接口
    - 层级：位于特权级模型的 U-mode
2. 应用程序二进制接口（Application Binary Interface,ABI)
    - 定义：ABI 是用户程序与运行环境（AEE）之间的二进制契约，定义了程序如何运行、调用函数、传参、链接等行为
    - 作用：让编译器生成的程序可在目标平台执行，保证用户程序和系统库/内核之间的兼容性
    - 组成：寄存器使用约定，函数调用约定，系统调用接口，二进制可执行文件格式(ELF，PE)
3. 管理态二进制接口(Supervisor Binary Interface,SBI)
    - 定义：SBI 是位于 S-mode 的操作系统内核 与 M-mode 固件（如 OpenSBI） 之间的标准接口。
    - 作用：提供统一的硬件抽象接口（如定时器、中断、CPU 启动等），使操作系统可以移植到不同硬件平台，而不需关心底层细节。
4. 管理态执行环境（Supervisor Execution Environment,SEE)
    - 定义：SEE 是支持操作系统内核运行的环境，运行在 S-mode（特权模式），由底层 SBI 固件和硬件提供支撑。
    - 作用：支持虚拟内存、任务调度、中断处理等核心功能，对外提供系统调用接口，为 AEE 提供服务，向下通过 SBI 接口调用底层功能
    - 组成：操作系统内核


## 编译系统

// TODO

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


## 交叉编译

在编写用户程序的时候，比如说一个 hello world 程序，从编写程序源码，编译程序到运行程序都在一台计算机上进行，即开发程序的计算机和运行程序的计算机是同一台计算机，而这台计算机大概率是基于 x86 架构的

我们要开发的 RISCV 的操作系统需要运行在 RISCV 架构的计算机上，即在开发机(本地机器)上进行开发操作系统，然后在 qemu 模拟的 RISCV 计算机上运行操作系统

要想在 x86 架构的开发机上编译出可以在 RISCV 架构上运行的程序，就需要使用交叉编译工具链：
- riscv64-unknown-elf-gcc：编译出 RISCV 架构的代码的交叉编译器
- riscv64-unknown-elf-ld：链接器
- riscv64-unknown-elf-objdump：反汇编工具
- riscv64-unknown-elf-gdb：调试器

## 编译 riscv64-unknown 工具链

```bash
# 安装相关依赖
sudo apt install libncurses-dev python3 python3-dev texinfo libreadline-dev       libgmp3-dev
# 从清华大学开源镜像站下载gdb源码(约23MB)
wget https://mirrors.tuna.tsinghua.edu.cn/gnu/gdb/gdb-13.1.tar.xz
# 解压gdb源码压缩包
tar -xvf gdb-13.1.tar.xz
# 进入gdb源码目录
cd gdb-13.1
mkdir build && cd build
# 配置编译选项，这里只编译riscv64-unknown-elf一个目标文件
../configure --prefix=/usr/local --target=riscv64-unknown-elf --enable-tui=yes

# 开始编译，这里编译可能消耗较长时间，具体时长取决于机器性能
make -j2
# 编译完成后进行安装
sudo make install
```

## 裸机程序

和应用程序的开发不同，裸机程序直接在硬件上运行、不依赖操作系统或其他软件层的程序。操作系统的开发就是裸机开发，直接与硬件交互，此时没有操作系统提供的抽象：文件系统、进程管理、设备驱动、虚拟化等


裸机程序的入口地址一般为 start，必须从最低层开始初始化整个运行环境，而应用程序的入口地址一般是 main，因为操作系统和运行时库已经提前完成了所有初始化，main 是程序执行的入口而不是程序加载的入口


## qemu 模拟器

qemu 是一个可以模拟计算机硬件的程序，提供了两种模拟方式：
1. 用户模式模拟（User-mode emulation）：只模拟用户空间程序，将针对特定架构的指令翻译为主机指令
2. ​系统模式模拟（System-mode emulation）：模拟完整的计算机系统，包括CPU、内存、设备等所有硬件

这里使用系统模式模拟一个 RISCV 指令集的计算机，然后编写代码，在开发机编译代码，然后在 qemu 模拟出的计算机上运行代码

## C 与 汇编的协同

// TODO



## qemu 的启动

qemu 会模拟计算机的启动过程，可以划分为以下几个过程：
1. 执行 qemu 在源代码中写死的一段简化的 OpenSBI 固件，相当于真是计算机的 BIOS/UEFI，固定位置为 0x1000 处，所以在 Makefile 的 qemu-gdb target 中加入 & 暂停 qemu 的执行，从 gdb 中也可以看到执行的第一段汇编代码就是 0x1000 处的代码，同时也是 qemu 源代码 hw/riscv/boot.c 中函数 riscv_setup_rom_reset_vec 中定义的数组。这段汇编指令执行完成之后默认会跳转到 0x80000000 处，这也是 RISC-V 的传统内核加载地址
```asm
0x1000 auipc t0,0x0      // 计算当前 PC (0x1000) 的高 20 位 + 0x0，存入 t0，此时 t0 = 0x1000。
0x1004 addi  a2,t0,40    // a2 = t0 + 40 = 0x1028，a2 可能指向某个数据（如设备树或启动参数）
0x1008 csrr  a0,mhartid  // 读取当前 CPU 核心的硬件线程 ID (mhartid)，存入 a0
0x100c ld    a1,32(t0)   // 从 t0 + 32 = 0x1020 处加载 64 位数据到 a1
0x1010 ld    t0,24(t0)   // 从 t0 + 24 = 0x1018 处加载 64 位数据到 t0
0x1014 jr t0             // 跳转到 to 指向的地址，即内核的入口 0x80000000
```
2. 执行 bootloader 的代码，加载操作系统的代码进内存，qemu启动的第一阶段固定跳转到地址0x80000000处，所以需要将bootloader加载到物理地址0x80000000处，这样然后qemu跳转到的0x80000000之后就开始执行 bootloader 的指令，而 bootloader 负责对硬件进行检查和初始化，然后加载操作系统

3. 此时开始执行操作系统的代码，操作系统初始化完成之后计算机就被操作系统控制了

但是 xv6 在 makefile 中加入了 -bios none 选项，也就是说，xv6 没有用到 bootloader，在执行完 qemu 内置的 openSBI 代码后直接跳转到 0x80000000 地址处执行 xv6 的代码

## 链接器脚本

由 qemu 的启动可以看出哪段代码该放到哪个地址都是有讲究的，而这就需要用到链接器脚本，链接器脚本是程序在链接的时候控制各个段该如何在内存中布局的配置文件。简单来说链接器脚本告诉链接器程序的代码，数据，符号该放到内存的哪个位置，按照什么顺序排布

链接器脚本的主要作用包括：
1. 指定程序入口地址
2. 定义程序各个段的布局
3. 控制代码和数据分布

在 kernel 目录下的 kernel.ld 文件就是用于控制内核代码在内存中布局的链接器脚本



## 使用 gdb 进行调试

需要安装 riscv64-unknown-elf-gdb

在 makefile 中增加 target：qemu-gdb，然后在 qemu 启动的时候指定 GDB 服务器的端口，-s 参数默认使用 1234 端口，也可以使用 -gdb tcp::port 指定

然后 -S 参数让 qemu 启动的时候就暂停下来，等待 gdb 的命令，这样可以调试 qemu 启动到内核加载这段时间的代码，否则会直接跳到内核加载完成后的 start 函数处调试


## 配置 vscode 调试

vscode 的调试依赖在 .vscode 文件夹下的两个配置文件：launch.json 和 task.json，下面是参考的两个配置文件：

- launch.json
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "debug xv6",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/kernel/kernel",
            "args": [],
            "stopAtEntry": true,
            "cwd": "${workspaceFolder}",
            "miDebuggerServerAddress": "localhost:26001",
            "miDebuggerPath": "/usr/local/bin/riscv64-unknown-elf-gdb",
            "environment": [],
            "externalConsole": false,
            "MIMode": "gdb",
            "setupCommands": [
                {
                    "description": "pretty printing",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ],
            "logging": {
                 "engineLogging": false,
                 "programOutput": true,
            },
            "preLaunchTask": "xv6build",
        }
    ]
}
```
- tasks.json
```json
{
  "version": "2.0.0",
  "tasks": [
      {
          "label": "xv6build",
          "type": "shell",
          "isBackground": true,
          "command": "make CPUS=1 qemu-gdb",
          "problemMatcher": [
              {
                  "pattern": [
                      {
                          "regexp": ".",
                          "file": 1,
                          "location": 2,
                          "message": 3
                      }
                  ],
                  "background": {
                      "beginsPattern": ".*Now run 'gdb' in another window.",
                      "endsPattern": "."
                  }
              }
          ]
      }
  ]
}
```
- 使用 vscode 调试比较方便，但是在一些特定的场景下还是使用 gdb 调试比较好
- 可以在调试控制台加上 -exec 执行 gdb 命令
- 使用 vscode 调试需要在 .gdbinit 文件中的 target remote 127.0.0.1:1234 一行加上 # 注释
