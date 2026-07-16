# dotfiles

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
expected_commit="$(git ls-remote https://github.com/asharca/dotfiles.git refs/heads/main | awk '{print $1}')"

(
  set -o pipefail
  curl -fsSL 'https://gist.githubusercontent.com/asharca/4756ff76e839454d8f6bd4470ba87cf3/raw/cfg-install.sh' |
    CFG_EXPECTED_COMMIT="$expected_commit" \
    bash -s -- --replace-existing --yes dev
)
```

> 直接执行远端脚本表示信任该 Gist 和 dotfiles 仓库。如需先审查内容，请先用 `curl -o` 下载后再执行。

## 管理配置

安装后使用 `config` 函数操作 bare repository：

```bash
config status
config add ~/.zshrc
config commit -m 'update zsh config'
config push
```

请始终显式添加文件，不要在 `$HOME` 执行 `config add -A`。
