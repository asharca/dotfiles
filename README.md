# dotfiles

[![Zsh CI](https://github.com/asharca/dotfiles/actions/workflows/zsh-ci.yml/badge.svg)](https://github.com/asharca/dotfiles/actions/workflows/zsh-ci.yml)

个人终端配置，使用 bare Git repository 管理 `$HOME` 下的文件。支持 macOS 与常见 Linux 发行版。

## 通过 curl 直接安装

完整开发环境：

```bash
(
  set -o pipefail
  curl -fsSL 'https://gist.githubusercontent.com/asharca/4756ff76e839454d8f6bd4470ba87cf3/raw/cfg-install.sh' |
    bash -s -- dev
)
```

`server` 仍会安装 essential、recommended、UV、trash-cli、zplug 与 tmux 插件；它只跳过 `yt-dlp`、`rtk` 和 Claude Code。它不是最小化服务器配置。

服务器环境（不安装 dev-only 工具）：

```bash
(
  set -o pipefail
  curl -fsSL 'https://gist.githubusercontent.com/asharca/4756ff76e839454d8f6bd4470ba87cf3/raw/cfg-install.sh' |
    bash -s -- server
)
```

### 安全替换已有的 `~/.cfg`

通过管道执行时 stdin 不是终端，因此替换模式必须显式添加 `--yes`：

```bash
(
  set -o pipefail
  curl -fsSL 'https://gist.githubusercontent.com/asharca/4756ff76e839454d8f6bd4470ba87cf3/raw/cfg-install.sh' |
    bash -s -- --replace-existing --yes dev
)
```

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
