# Termux 分支

本分支以 `main` 的所有跟踪文件为基础，额外保留原有 `.termux` 目录中的配色、字体与 Android 设置。Kitty、IDEA Vim、macOS 专有程序的配置会被保存，但并不代表它们可在 Android 原生运行。

## 首次安装：原生 Termux

建议使用 F-Droid / GitHub 发布的近期 Termux，先确认能联网；请在 **Termux App 本身**运行，不要在 proot Linux 容器中执行。请先检查将被部署的仓库和脚本，再决定是否执行。

```sh
pkg update -y
pkg install -y git zsh bash
git clone --single-branch --branch termux https://github.com/asharca/dotfiles.git "$HOME/dotfiles-termux-src"
less "$HOME/dotfiles-termux-src/termux-setup.sh"
bash "$HOME/dotfiles-termux-src/termux-setup.sh" server
```

首次安装默认使用 `server`；如需 Android 上的编译工具链，可改为 `dev`（额外尝试安装 clang/cmake/rust）。脚本会：

1. 使用 `pkg` 安装原生 Termux 依赖，而不是 Homebrew、sudo 或 Linux `chsh`。
2. 新建 `~/.cfg` bare Git 仓库，固定使用 `termux` 分支；**已存在 ~/.cfg 时立即拒绝覆盖**。
3. 使用 `rsync --backup` 将克隆仓库的全部配置复制到 HOME，原有被替换的文件保存到 `~/.config-backup/termux.XXXXXXXXXX/`；不会删除其他 HOME 文件。
4. 安装 zplug 声明的 Zsh 插件、tmux TPM，配置 Termux 自带的 shell 切换，并重新加载终端设置。

安装后重启 Termux 或执行：

```sh
exec zsh
zsh ~/.config/zsh/tests/run.zsh
nvim --version
nvim
```

如果网络中断，已安装的模块化 Zsh 仍可启动（插件可能提示缺失）；重新运行下面的 Termux bootstrap 来补齐依赖：

```sh
bash ~/.config/zsh/bootstrap/install-termux.sh server
# 或通过已有的跨平台入口：
zsh ~/.config/zsh/bootstrap/install.zsh server
```

安装前预览（不触碰包管理器）：

```sh
bash ~/.config/zsh/bootstrap/install-termux.sh --dry-run dev
```

## 更新现有 termux 安装

如果已经安装了 `~/.cfg`，不要运行首次安装脚本。先检查已跟踪文件是否有未提交修改，然后只允许 fast-forward：

```sh
config status --short --untracked-files=no
config pull --ff-only origin termux
bash ~/.config/zsh/bootstrap/install-termux.sh server
exec zsh
```

如果 `config` 函数尚未加载，用 `git --git-dir="$HOME/.cfg" --work-tree="$HOME"` 代替。遇到本地修改或未跟踪文件冲突时，先备份/手工处理，**不要使用** `reset --hard`、强制 checkout 或直接清空 `~/.cfg`。首次安装前已有的 dotfiles、SSH 凭据或其他个人数据不应被主动删除。

## Neovim 与其他 Android 差异

- Neovim 需 **0.11.2 或以上**（以当前 LazyVim 版本为准），先通过 `pkg upgrade` 更新。第一次执行 `nvim` 需要网络下载 lazy.nvim/LazyVim 插件。后续可运行 `:checkhealth`、`:Lazy sync`。
- Android/Bionic 下禁用 Mason 自动管理的 LSP/DAP 和部分需要 root 的插件；使用 `pkg`、`npm` 或本机可执行文件安装语言服务器，例如 `pkg install lua-language-server`（仓库提供时）。缺少语言服务器不应阻止基本编辑器启动。
- Blink Completion 固定稳定 v1 并使用 Lua fuzzy matcher，避免依赖 Android 未必可用的本机编译程序。此分支移除了旧 main 分支的 Blink lock 项，首次 `:Lazy sync` 后会生成新的锁定记录。Treesitter 解析器不在启动时自动编译。
- `~/.termux/colors.sh`、`~/.termux/fonts.sh` 可以互动切换配色与字体，会调用 `termux-reload-settings`（存在时）。
- 如果安装 `termux-api` 并配套安装 **Termux:API App**，Zsh 的 `copy` 别名会优先使用 Android 剪贴板。未安装时不影响正常终端操作。
- `main` 中的 Kitty、Homebrew、Claude Code、OpenCode、rtk、桌面专属插件/工具只是配置文件被完整保留，不能承诺 Android 上全部可执行；Termux 原生安装器只安装确认适用于该环境的基础工具。zoxide/fzf/tmux/nvim/git 等核心工具优先保证可启动。

## 检查与限制

本分支带有 GitHub Actions 的语法检查、完整文件树检查和模拟 Termux 环境的 Zsh 启动测试。Ubuntu runner **不等于 Android 真机**：下载失败、设备架构、终端 App 版本或第三方插件更新仍可能产生差异。设备上请使用 `zsh ~/.config/zsh/tests/run.zsh`、`nvim`、`tmux` 实测。

