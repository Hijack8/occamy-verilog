# Readme

## 0. 目录

- [1. 项目结构](#1-项目结构)

- [2. 脚本说明与环境配置](#2-脚本说明与环境配置)

  - [2.1 主脚本 synopsys.sh](#21-主脚本-synopsyssh)

  - [2.2 TCL 脚本 main.tcl](#22-tcl-脚本-maintcl)

  - [2.3 环境变量设置](#23-环境变量设置)

- [3. 使用方法](#3-使用方法)

  - [3.1 设置环境变量](#31-设置环境变量)

  - [3.2 运行综合脚本](#32-运行综合脚本)

  - [3.3 清理环境](#33-清理环境)

- [4. DC综合流程](#4-dc综合流程)

- [5. 注意事项](#5-注意事项)

---

## 1. 项目结构

```

project_root/

├── synopsys.sh                 # 主 Bash 脚本

├── script/

│   ├── main.tcl                # 主 tcl 脚本，调用下面各脚本（除unity_setup.tcl）

│   ├── check_design.tcl

│   ├── common_functions.tcl

│   ├── generate_reports.tcl

│   ├── read_design.tcl

│   ├── save_design.tcl

│   ├── set_constraints.tcl

│   ├── setup_environment.tcl

│   ├── synthesis.tcl

│   └── unity_setup.tcl         # 是上述tcl脚本的合并，单独执行效果与main.tcl一致

├── rtl/                        # 存放 Verilog 源代码

├── work/                       # 工作目录

├── mapped/                     # 存放综合后的网表

├── report/                     # 存放综合报告

├── library/                    # 库文件目录（如标准单元库）

├── config/                     # 配置文件目录（如有需要）

├── unmapped/                   # 存放未映射的网表（如有需要）

```

---

## 2. 脚本说明与环境配置

### 2.1 主脚本 `synopsys.sh`

`synopsys.sh` 是项目的主脚本，负责环境配置、运行综合和清理工作。脚本主要包含以下部分：

- **函数定义**：

  - `setup_env`：设置环境变量。

  - `run_script`：运行综合脚本。

  - `clean_env`：清理生成的文件和目录。

- **主程序逻辑**：根据传入的参数执行相应的功能。

### 2.2 TCL 脚本 `main.tcl`

`main.tcl` 是 Design Compiler 的配置和运行脚本，主要负责：

- 清除之前的设计数据。

- 设置 Design Compiler 的选项和环境变量。

- 读取 Verilog 设计文件。

- 设置综合约束（时序、面积等）。

- 运行综合并生成报告。

- 保存综合后的设计和约束文件。

### 2.3 环境变量设置

`setup_env` 函数设置了多个环境变量，用于指定项目中的各种路径和配置：

- `TOP_MODULE`：顶层模块名称，默认为当前目录名

- `DC_PATH`：Design Compiler 的安装路径，该目录下应包含 `dc_shell` 可执行文件

- `SYN_ROOT_PATH`：项目的根目录，即脚本所在的当前目录

- `RTL_PATH`：Verilog 源代码目录，默认为 `$SYN_ROOT_PATH/rtl`

- `WORK_PATH`：Design Compiler 的工作目录，默认为 `$SYN_ROOT_PATH/work`

- `SCRIPT_PATH`：存放 TCL 脚本的目录，默认为 `$SYN_ROOT_PATH/script`

- `MAPPED_PATH`：存放综合后网表的目录，默认为 `$SYN_ROOT_PATH/mapped`

- `REPORT_PATH`：存放综合报告的目录，默认为 `$SYN_ROOT_PATH/report`

- `LIB_PATH`：库文件目录，默认为 `$SYN_ROOT_PATH/library`

---

## 3. 使用方法

> input `alias syn="source ./synposys.sh"` in your shell, then your life will be saved.

### 3.1 设置环境变量

在首次运行之前，可以使用以下命令设置环境变量：

```bash

source ./synopsys.sh --setup [TopModuleName] [DCInstallationPath]

```

> **`source` 是对于脚本 `synopsys.sh` 的执行是必要的**
>
> 由于脚本需要设置环境变量（`$TOP_MODULE`），而如果以 `./synopsys.sh` 的方式运行，shell 会在子进程中设置环境变量，无法影响当前 shell 的环境

- `TopModuleName`：可选参数，指定顶层模块名称，默认为当前目录名。

- `DCInstallationPath`：可选参数，指定 Design Compiler 的安装路径。

示例：

```bash

source ./synopsys.sh --setup my_top_module /path/to/design_compiler

```

### 3.2 运行综合脚本

运行综合流程：

```bash

source ./synopsys.sh --run

```

该命令将执行以下操作：

- 继承 `setup_env` 函数设置的环境变量，如果未设置则使用默认值

- 调用 `run_script` 函数，运行综合流程。

### 3.3 清理环境

如果需要清理生成的文件和目录，可以使用：

```bash

source ./synopsys.sh --clean

```

该命令将执行以下操作：

- 调用 `clean_env` 函数，删除指定的文件和目录，保留必要的配置文件。

---

## 4. DC综合流程

`main.tcl` 是 Design Compiler 的配置和运行脚本，主要包含以下步骤：

1. **禁用命令回显**：

   ```tcl

   set echo off

   set verbose off

   ```

2. **定义阶段提示函数**：

   ```tcl

   proc stage_message {stage_num stage_desc is_start} {
   
        # 输出美观的阶段提示信息

   }

   ```

3. **阶段 1：清除之前的设计数据**：

   ```tcl

   stage_message 1 "Cleaning design environment (remove_design -all)" 1

   remove_design -all

   stage_message 1 "Design environment cleaned" 0

   ```

4. **阶段 2：设置 Design Compiler 选项**：

   - 从环境变量中获取路径和配置。

   - 设置搜索路径、目标库和链接库。

5. **阶段 3：读取设计文件**：

   - 定义递归获取 Verilog 文件的函数。

   - 读取 `RTL_PATH` 目录下的所有 Verilog 文件。

   - 设置当前设计为顶层模块 `TOP_MODULE`。

6. **阶段 4：检查链接和设计完整性**：

   - 执行 `link` 和 `check_design`，检查设计是否正确链接和无错误。

7. **阶段 5：设置时序和面积约束**：

   - 创建时钟约束。

   - 定义设置黑盒模块延迟的函数，设置 RAM 和 FIFO 模块的读写延迟。

   - 设置最大面积约束。

8. **阶段 6：执行综合**：

   - 使用高努力级别进行综合。

9. **阶段 7：生成报告**：

   - 创建报告目录（如果不存在）。

   - 生成各种综合报告，并保存到 `REPORT_PATH`。

10. **阶段 8：保存综合后的设计**：

​    - 创建保存综合结果的目录（如果不存在）。

​    - 保存综合后的网表（Verilog 格式）、设计（DDC 格式）和约束文件（SDC 格式）。

11. **阶段 9：退出 Design Compiler**：

​    ```tcl

​    quit

​    ```

---

## 5. 注意事项

- **环境变量**：在运行脚本之前，确保脚本中的路径和环境变量符合您的实际环境。

- **Design Compiler 安装路径**：根目录下的shell脚本需要指定 Design Compiler 的安装路径，在命令中指定或者其路径早已存在于你的环境变量中，这两个条件至少需要一个满足。

- **许可证管理器**：确保 Synopsys 许可证管理器已正确配置和运行，以避免在运行 `dc_shell` 时出现许可证错误。

- **Verilog 源代码**：请将您的 Verilog 源代码放置在 `rtl` 目录下，脚本会自动递归读取该目录中的所有 `.v` 文件。

- **库文件**：请将所需的库文件（如标准单元库）放置在 `library` 目录下，并在脚本中正确指定库文件名。

- **日志文件**：综合过程的详细日志将保存到 `execute.log` 文件中，您可以查看该文件了解综合的详细信息。

---
