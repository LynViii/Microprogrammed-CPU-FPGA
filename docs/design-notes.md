# Design notes

这里整理控制字、微程序入口和课程测试，方便阅读 RTL 与 `rom.coe` 时对照。

## 指令格式

CPU 使用 16 位定长指令：

```text
15                 8 7                  0
+-------------------+--------------------+
|      opcode       |      address       |
+-------------------+--------------------+
```

高 8 位送入 IR，低 8 位用于直接寻址或跳转目标。`NOT`、`SHR`、`SHL`、`SAR`、`SAL` 只操作当前 ACC，因此这些指令的低 8 位不参与运算。

## 32 位控制字

ROM 每个地址保存一个 32 位控制字 `cs`。各模块在时钟上升沿检查对应控制位。

| 位 | 微操作 |
|---:|---|
| C0 | `CU <= 0` |
| C1 | CU 根据 IR opcode 跳转到指令微程序入口 |
| C2 | `CU <= CU + 1` |
| C3 | `PC <= MBR[7:0]` |
| C4 | `MAR <= MBR[7:0]` |
| C5 | `IR <= MBR[15:8]` |
| C6 | 未使用 |
| C7 | `RAM[MAR] <= MBR` |
| C8 | `MBR <= RAM` |
| C9 | `BR <= MBR` |
| C10 | `ACC <= 0` |
| C11 | ALU：`ACC + BR` |
| C12 | `PC <= 0` |
| C13 | `PC <= PC + 1` |
| C14 | `MAR <= PC` |
| C15 | ALU 内部锁存 BR |
| C16 | `MBR <= ACC` |
| C17 | ALU 内部锁存 ACC |
| C18 | `ACC <= ALU result`，同时更新 `flag` |
| C19 | `MR <= ALU result[31:16]` |
| C20 | `MBR <= MR` |
| C21 | ALU：`ACC - BR` |
| C22 | ALU：有符号 `ACC * BR` |
| C23 | ALU：算术右移 |
| C24 | ALU：算术左移 |
| C25 | ALU：逻辑右移 |
| C26 | ALU：逻辑左移 |
| C27 | ALU：AND |
| C28 | ALU：OR |
| C29 | ALU：XOR |
| C30 | ALU：NXOR |
| C31 | ALU：NOT |

`flag` 在 C18 写回 ACC 时由结果最高位更新。`JMPGEZ` 将 `flag == 0` 作为非负条件。

## 公共 FETCH

所有机器指令先经过公共取指流程：

| CAR | 微操作 | 控制位 |
|---:|---|---|
| `00` | `MAR <= PC` | C14, C2 |
| `01` | `MBR <= RAM`, `PC <= PC + 1` | C8, C13, C2 |
| `02` | `IR <= MBR[15:8]`, `MAR <= MBR[7:0]` | C5, C4, C2 |
| `03` | 根据 IR 跳到指令入口 | C1 |

FETCH 的第三步同时把低 8 位地址送入 MAR，因此带内存操作数的指令进入自身微程序后可以继续读取操作数。

## 微程序入口

入口地址与 `rtl/CU.v` 中的译码逻辑一致。

| Opcode | 指令 | 入口 CAR |
|---:|---|---:|
| `01` | STORE X | `50` |
| `02` | LOAD X | `54` |
| `03` | ADD X | `27` |
| `04` | SUB X | `2E` |
| `05` | JMPGEZ X | `5B` / `5C` |
| `06` | JMP X | `5F` |
| `07` | HALT | `62` |
| `08` | MUL X | `35` |
| `0A` | AND X | `06` |
| `0B` | OR X | `0D` |
| `0C` | NOT | `14` |
| `0D` | SHR | `41` |
| `0E` | SHL | `3C` |
| `0F` | SAR | `4B` |
| `10` | SAL | `46` |
| `11` | XOR X | `19` |
| `12` | NXOR X | `20` |

`HALT` 对应 `0x62`，该地址的控制字为 `0x00000000`。

## 典型执行流程

以 `ADD X` 为例，FETCH 结束时 MAR 已经指向 X：

```text
27  MBR <= RAM[X]
28  BR <= MBR
29  ALU 锁存 ACC 和 BR
2A  ALU 执行 ACC + BR
2B  ACC <= ALU result, CAR <= 0
```

`MUL X` 的流程相近，但使用有符号乘法。32 位结果低 16 位写入 ACC，高 16 位写入 MR。

`JMPGEZ X` 根据 `flag` 选择入口：非负进入 `0x5B`，执行 `PC <= MBR[7:0]`；负数进入 `0x5C`，不修改 PC，回到 FETCH。

## 课程测试程序

课程实验使用四组程序覆盖主要指令：

1. `1 + 2 + ... + 10` 循环累加：覆盖 LOAD / STORE / ADD / SUB / JMPGEZ / HALT，最终 `ACC = 0037H`。
2. 乘法与逻辑运算：`7995H × CD50H = E7ED4F90H`，MUL 后 `MR = E7EDH`、`ACC = 4F90H`；随后继续执行 AND / OR / XOR / NXOR / NOT，最终 `ACC = 0F0FH`。
3. 移位运算：以 `8001H` 为初值依次执行 SAR / SHR / SHL / SAL，最终 `ACC = 8000H`。
4. 无条件跳转：`JMP 03H` 跳过地址 `01H`、`02H`，随后执行 `LOAD 11`，最终 `ACC = ABCDH`。

仓库中的 `ip/blk_ram/ram.coe` 保存课程工程使用的程序和数据初始化内容。需要换测试程序时，只需修改 RAM 初始化内容并重新生成 IP output products。

## 实现细节

- Block RAM / ROM 为同步存储器，地址、输出和寄存器装载需要按时钟关系安排微操作。
- 同一模块若有多个控制位同时有效，执行结果会受到 RTL 中赋值顺序影响，因此控制字应避免冲突控制。
- `flag` 只在 C18 写回 ACC 时更新，条件跳转使用最近一次写回 ACC 后的符号状态。
- 乘法结果为 32 位，完整结果由 `{MR, ACC}` 组成。