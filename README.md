# 主目录使用规范

这个目录是 macOS 主目录。系统目录和工具配置保留原位；只有个人资料和项目按下列规则存放。

## 顶层目录

| 目录 | 用途 | 规则 |
| --- | --- | --- |
| `Desktop` | 临时可见文件 | 每周清空或移入正式目录，不长期存放项目。 |
| `Documents` | 个人正式文档 | 按主题建一层目录，例如 `Documents/财务/`、`Documents/证件/`。 |
| `Downloads` | 下载收件箱 | 新下载的文件先放这里；确认用途后移动，非存档文件定期删除。 |
| `Github` | 外部开源仓库的阅读与试用区 | 只放第三方仓库、示例和临时验证；不作为自己项目的长期开发目录。 |
| `Code` | 唯一的长期代码工作区 | 所有自己维护、持续开发或需要交付的代码都放这里，不论仓库托管在 GitHub、GitLab 还是本地。推荐按类型分组：`apps/`、`scripts/`、`experiments/`。 |
| `Work` | 工作项目、方案、交付资料 | 一个项目一个目录；代码项目可链接或引用 `Code`/`Github` 中的仓库，不复制仓库。 |
| `Pictures`、`Movies`、`Music` | 媒体库 | 仅存放对应媒体，不混入项目附件。 |
| `Public` | 对外共享文件 | 只放准备共享的副本，不作为唯一存档。 |
| `bin` | 个人可执行脚本 | 脚本应可独立运行，并在文件开头写明用途。 |

## 不要整理的目录

以下目录由 macOS、应用或开发工具管理，不手动合并、移动或批量删除：

- `Library`、`Applications`、`go`
- 所有以 `.` 开头的目录和文件，例如 `.config`、`.ssh`、`.npm`、`.nvm`、`.pi`

清理前先确认对应应用或工具已卸载；`~/.ssh`、shell 配置和密钥文件尤其不要随意移动。

## 项目目录规范

每个长期项目使用一个独立目录，推荐结构如下：

```text
项目名/
├── README.md        # 项目目的、运行方式、重要链接
├── docs/            # 方案、决策、使用说明
├── src/             # 源代码（项目需要时）
├── scripts/         # 项目专用脚本（项目需要时）
├── data/            # 可再生成或原始数据；大文件不提交 Git
├── output/          # 构建产物、报告、导出结果；可删除时注明生成方式
└── archive/         # 已结束且仍需保留的阶段性资料
```

不需要的目录不要预先创建。使用 Git 的项目应补充 `.gitignore`，避免提交密钥、依赖目录、构建产物和大文件。

## 文件命名

- 新项目目录：使用清晰的名称，英文项目用 `kebab-case`，中文项目可直接使用中文名称。
- 日期文件：使用 `YYYY-MM-DD-主题`，例如 `2026-03-31-周报.md`。
- 版本文件：使用 `v1`、`v2` 或 Git 标签；不要使用“最终版”“最终最终版”。
- 临时文件：文件名带 `tmp` 或放入 `Downloads` / `Desktop`，完成后删除或归位。

## 日常流程

1. 下载文件先进入 `Downloads`，确认用途后在当天归位。
2. 新代码一律放入 `Code`：项目托管平台不决定目录位置。只有第三方仓库的阅读、试用和一次性验证放入 `Github`；需要长期修改、交付或维护时，将仓库迁入 `Code`。
3. 项目结束后保留最终交付物和 `README.md`，其余可再生成内容删除或放到项目的 `archive/`。
4. 每月检查一次 `Desktop`、`Downloads` 和没有说明文件的项目目录。

## 当前目录的处理原则

替换是非破坏性的：

- 旧 bare repository 会被原子归档到 `~/.cfg-repository-backups/.../repo.git`。
- 被新配置替换的 HOME 文件会保存到 `~/.config-backup/...`。
- 不带 `--replace-existing` 时，安装器默认复用并验证已有的 `~/.cfg`。
- symlink、损坏仓库与安装器保留路径会被拒绝；默认复用模式也会严格校验 origin。
- checkout 中断后，使用相同仓库来源再次普通运行即可续装。

### 固定一次安装所使用的 commit

先读取远端 `main`，再把该 SHA 传给管道右侧的 Bash。若 clone 期间远端发生变化，安装器会停止：

```bash
(
  set -e
  expected_commit="$(git ls-remote https://github.com/asharca/dotfiles.git refs/heads/main | awk '{print $1}')"
  if [[ ! "$expected_commit" =~ ^[0-9a-f]{40}$ ]]; then
    printf '无法读取远端 main commit，安装已停止。\n' >&2
    exit 1
  fi

  set -o pipefail
  curl -fsSL 'https://gist.githubusercontent.com/asharca/4756ff76e839454d8f6bd4470ba87cf3/raw/cfg-install.sh' |
    CFG_EXPECTED_COMMIT="$expected_commit" \
    bash -s -- --replace-existing --yes dev
)
```

> 直接执行远端脚本表示信任该 Gist 和 dotfiles 仓库。如需先审查内容，请先用 `curl -o` 下载后再执行。

## 更新现有安装

安装器在发现有效的 `~/.cfg` 时会复用并验证它，但不会自动拉取远端更新。先确认工作区没有未提交的修改，再使用 fast-forward 更新，避免意外产生 merge commit：

```bash
config status --short --untracked-files=no
config pull --ff-only origin main
exec zsh
```

如果当前 shell 还没有加载 `config` 函数，可以直接使用完整命令：

```bash
git --git-dir="$HOME/.cfg" --work-tree="$HOME" \
  pull --ff-only origin main
exec zsh
```

如果状态命令显示已跟踪文件有修改，请先提交修改或手动处理冲突，再执行更新。bare repository 默认不列出 HOME 中的未跟踪文件；需要检查某个配置目录时，使用 `config status --short --untracked-files=all -- .config/zsh`。不要在 HOME 中不限定路径地扫描全部未跟踪文件。即使存在未跟踪冲突，Git 也会拒绝覆盖并停止 pull。若本次更新改动了软件包或 zplug 插件声明，请在拉取后重新执行上方对应的 `dev` 或 `server` 安装命令，以补齐依赖。zplug 只在 bootstrap 阶段安装插件；日常 shell 启动会直接加载已安装的插件文件。

## SSH 使用方式

`ssh` 默认直接运行系统 OpenSSH，不根据 `KITTY_WINDOW_ID` 等继承的环境变量自动切换到 Kitty。SSH 远程会话、tmux 和普通终端中都使用相同的行为，主机密钥校验保持不变。

需要 Kitty 的 SSH 增强功能时，在实际的 Kitty 窗口中显式运行：

```bash
kitty +kitten ssh user@host
```

更新后执行 `exec zsh`；如需保留当前 shell，可运行 `source ~/.config/zsh/aliases/system.zsh`，这也会清除旧的 `ssh` 函数和别名。

## 验证 Zsh 配置

修改配置后运行回归测试：

```bash
zsh ~/.config/zsh/tests/run.zsh
```

GitHub Actions 会在 `ubuntu-24.04` x64 与 `macos-15` ARM64 上，以隔离 HOME 执行固定 revision 的 Gist 安装器。测试覆盖 `curl | bash ... server`、文件重跑、bare repository 校验、插件加载、登录 shell 和必需工具失败传播。包管理器、`sudo` 与 `chsh` 使用本地 fixture，不会在 runner 上安装整套工具或修改默认 shell。

测量非 TTY 启动开销：

```bash
hyperfine --warmup 3 --runs 15 \
  'zsh -dfi -c exit' \
  'zsh -i -c exit'
```

历史过滤只能作为最后一道保护，而且不会回溯清理已有历史。不要在命令行直接粘贴长期凭据；临时敏感命令至少以空格开头，利用 `HIST_IGNORE_SPACE` 阻止写入历史。

Linux 默认不会自动进入 tmux，避免每个交互终端被强制接管。需要恢复自动连接/创建会话时，在 `~/.zshenv` 中设置 `export ZSH_AUTO_TMUX=1`。

## 管理配置

安装后使用 `config` 函数操作 bare repository：

```bash
config status
config add ~/.zshrc
config commit -m 'update zsh config'
config push
```

bare repository 默认隐藏未跟踪文件。检查准备新增的配置目录时，显式限定路径：

```bash
config status --short --untracked-files=all -- .config/zsh
```

请始终显式添加文件，不要在 `$HOME` 执行 `config add -A`。
