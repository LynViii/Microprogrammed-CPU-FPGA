# Design notes

这份说明只整理实现中比较容易忘记的部分：控制字、微程序入口和测试程序。详细实验过程没有直接搬进仓库，表中的内容按 RTL、ROM 初始化文件和课程报告交叉核对。

## 指令格式

CPU 使用 16 位定长指令：

```text
15                 8 7                  0
+-------------------+--------------------+
|      opcode       |   address / data   |
+-------------------+--------------------+
```

高 8 位送入 IR，低 8 位用于直接寻址或跳转目标。`NOT`、`SHR`、`SHL`、`SAR`、`SAL` 实际只操作当前 ACC，因此这些指令的低 8 位在当前实现中不参与运算。

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
| C6 | 当前未使用 |
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

`flag` 在 ACC 接收 ALU 结果时由结果最高位更新。当前 `JMPGEZ` 把 `flag == 0` 解释为非负并执行跳转。

## 公共 FETCH

所有机器指令先经过公共取指流程：

| CAR | 微操作 | 控制位 |
|---:|---|---|
| `00` | `MAR <= PC` | C14, C2 |
| `01` | `MBR <= RAM`, `PC <= PC + 1` | C8, C13, C2 |
| `02` | `IR <= MBR[15:8]`, `MAR <= MBR[7:0]` | C5, C4, C2 |
| `03` | 根据 IR 跳到指令入口 | C1 |

这里在 FETCH 的第三步就把低 8 位地址送入 MAR，因此带内存操作数的指令进入自己的微程序后可以继续完成 RAM 读取。

## 微程序入口

入口地址直接对应 `rtl/CU.v` 中的译码逻辑。

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

`HALT` 对应 `0x62`，ROM 中该地址控制字为 0，因此 CPU 停留在当前状态。

## 典型执行流程

以 `ADD X` 为例，FETCH 结束时 MAR 已经指向 X。随后：

```text
27  MBR <= RAM[X]
28  BR <= MBR
29  ALU 锁存 ACC 和 BR
2A  ALU 执行 ACC + BR
2B  ACC <= ALU result, CAR <= 0
```

`MUL X` 的流程相近，但使用 signed 乘法。32 位结果低 16 位写入 ACC，高 16 位写入 MR。

`JMPGEZ X` 在进入指令微程序前判断 `flag`：非负进入 `0x5B` 并执行 `PC <= MBR[7:0]`；负数进入 `0x5C`，不修改 PC，直接回到 FETCH。

## 课程测试程序

课程实验中使用过四类测试来覆盖指令集：

1. `1 + 2 + ... + 10` 的循环累加，覆盖 LOAD / STORE / ADD / SUB / JMPGEZ / HALT，最终 ACC 为 `0037H`。
2. 乘法和逻辑运算，覆盖 MUL / AND / OR / XOR / NXOR / NOT。测试中的 `7995H × CD50H` 得到 `E7ED4F90H`，因此 MUL 后 `MR=E7EDH`、`ACC=4F90H`。
3. 以 `8001H` 为初值依次测试 SAR / SHR / SHL / SAL，观察算术右移和逻辑右移的差别。
4. 使用 `JMP 03H` 跳过中间指令，验证 PC 无条件装载目标地址。

仓库当前的 `ip/blk_ram/ram.coe` 保留原工程实际使用的初始化内容。如果要复现某一组课程测试，可替换 RAM 的 COE 内容后重新生成 IP output products，再运行仿真或生成 bitstream。

## 实现时容易踩的点

- Block RAM / ROM 是同步存储器，送地址、得到输出、再装入寄存器需要按时钟关系安排微操作，不能按组合存储器理解。
- 同一模块的多个控制位若同时有效，会受到 RTL 中语句顺序影响，因此 ROM 控制字应避免产生冲突控制。
- `flag` 只在 C18 写回 ACC 时更新，条件跳转依赖的是最近一次真正写回 ACC 的 ALU 结果。
- 乘法结果是 32 位；只看 ACC 会丢掉高 16 位，完整结果需要拼接 `{MR, ACC}`。
