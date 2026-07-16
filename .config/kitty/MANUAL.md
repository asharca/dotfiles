# Kitty 使用手册

> 适配本机配置(kitty 0.47.4 / macOS)。快捷键已对照 [kitty 官方文档](https://sw.kovidgoyal.net/kitty/) 与源码核对。
>
> 约定:`⌘`=Command,`⌥`=Option/Alt,`⌃`=Control,`⇧`=Shift。
> kitty 里的 **`kitty_mod`** 默认等于 **`⌃⇧`(Ctrl+Shift)**。macOS 上 `⌘` 系快捷键和 `⌃⇧` 系快捷键**同时有效**,下面优先列 `⌘`。

---

## 1. 核心概念

kitty 用三层结构组织程序(类似平铺窗口管理器):

```
OS 窗口 (OS window)           ← 操作系统级别的窗口
  └── 标签页 (Tab)            ← 一个 OS 窗口里有多个 Tab
        └── 窗口 (Window)     ← 一个 Tab 里有多个「窗口」= 分屏 pane
```

- **OS 窗口**:macOS Dock 里看到的那个窗口。
- **标签页 Tab**:底部标签栏里的每一项(你的配置:斜切 Powerline 风格、底部)。
- **窗口 Window**:Tab 内部的分屏。kitty 自带分屏,**不需要 tmux**。
- **布局 Layout**:自动排列一个 Tab 内的多个窗口(已改回 kitty 默认 `enabled_layouts *`,启用全部 7 种布局)。

---

## 2. 你的自定义快捷键(最常用,优先记这些)

| 快捷键 | 作用 | 说明 |
|---|---|---|
| `⌘B` | 光标按词左移 | 发送 `⌥B`,等价 shell 的 backward-word |
| `⌘F` | 光标按词右移 | 发送 `⌥F`,等价 shell 的 forward-word |
| `⌘D` | 向右删一个词 | 发送 `⌥D`,等价 shell 的 delete-word |

---

## 3. 快捷键速查(默认键)

### 标签页 Tab

| 快捷键 | 作用 |
|---|---|
| `⌘T` | 新建标签页 |
| `⌘W` | 关闭标签页 |
| `⇧⌘]` | 下一个标签页 |
| `⇧⌘[` | 上一个标签页 |
| `⌃Tab` / `⌃⇧Tab` | 下一个 / 上一个标签页 |
| `⇧⌘I` | 设置标签页标题 |
| `⌃⇧.` / `⌃⇧,` | 标签页前移 / 后移 |

### 窗口 / 分屏 Window

| 快捷键 | 作用 |
|---|---|
| `⌘↩` (Enter) | 新建窗口(分屏) |
| `⇧⌘D` | 关闭当前窗口 |
| `⌃⇧]` / `⌃⇧[` | 下一个 / 上一个窗口 |
| `⌘1`…`⌘9` | 聚焦第 1…9 个**窗口**(注意:是窗口不是标签页) |
| `` ⌃⇧` `` | 把当前窗口移到最前 |
| `⌃⇧F7` | 可视化选择并聚焦窗口 |
| `⌃⇧F8` | 可视化交换两个窗口 |
| `⌘N` | 新建 **OS 窗口** |

> 分屏用原生:在 `splits` 布局下按 `⌘↩`(或 `⌃⇧↩`)即新建一个分屏窗口。

### 布局 Layout

| 快捷键 | 作用 |
|---|---|
| `⌃⇧L` | 切换到下一个布局(在全部 7 种布局间循环) |
| `⌃⇧R` | 进入调整窗口大小模式(方向键/`hjkl` 调,回车确认) |

当前为 kitty 默认的 `enabled_layouts *`,7 种布局循环顺序如下:

- **fat**:一个大窗口在上,其余平铺在下。
- **grid**:所有窗口等分成网格。
- **horizontal**:所有窗口左右并排。
- **splits**:自由的横竖分屏(树状),手动 `⌃⇧↩` 切分。
- **stack**:同一时间只显示一个最大化窗口(类似「全屏当前 pane」)。
- **tall**:一个大窗口在左,其余堆叠在右。
- **vertical**:所有窗口上下堆叠。

> 只想用某几种?把 `enabled_layouts` 改成如 `splits,stack` 即可,`⌃⇧L` 就只在这几种间切。

### 滚动 & 回滚历史 Scrollback

| 快捷键 | 作用 |
|---|---|
| `⌘↑` / `⌘↓` | 上滚 / 下滚一行 |
| `⌘PageUp` / `⌘PageDown` | 上 / 下翻页 |
| `⌘Home` / `⌘End` | 跳到顶部 / 底部 |
| `⌃⇧/` | 在回滚历史里**搜索** |
| `⌃⇧H` | 在分页器(less)里打开**完整回滚历史**(保留颜色) |
| `⌃⇧G` | 在分页器里查看**上一条命令的输出** |

> 注意:进入全屏程序(如 nvim、less)后,滚动键会交给该程序处理,不再滚 kitty 历史。
> 你的历史缓冲已设为 **20000 行**。

### 复制 / 粘贴 Clipboard

| 快捷键 | 作用 |
|---|---|
| 鼠标选中文本 | **自动复制**到系统剪贴板(你启用了 `copy_on_select`) |
| `⌘C` | 有选区则复制,无选区则透传(`copy_or_noop`) |
| `⌘V` | 粘贴 |
| `⌃⇧S` | 从「primary 选区」粘贴 |

### 字号 Font size

| 快捷键 | 作用 |
|---|---|
| `⌘+` / `⌘=` | 放大字号 |
| `⌘-` | 缩小字号 |
| `⌘0` | 重置字号 |

### 配置 & 杂项 Misc

| 快捷键 | 作用 |
|---|---|
| `⌃⌘,` | **重载配置**(改完 kitty.conf 后按这个) |
| `⌘,` | 用 `nvim` 打开配置文件编辑 |
| `⌥⌘,` | 打开「调试配置」窗口 |
| `⌃⇧E` | **hints 模式**:高亮屏幕上的 URL / 路径,按字母键选中打开 |
| `⌃⌘F` | 切换全屏 |
| `⌃⇧F10` | 切换最大化 |
| `⌃⇧F3` | 命令面板(Command Palette,搜索所有动作) |
| `⌃⇧Escape` | 打开 kitty 内置 shell(调试/远程控制) |
| `⌃⇧Delete` | 重置终端 |
| `⌘K` | 清屏(清到光标处) |
| `⌘L` | 清除上一条命令的回显 |
| `⌃⌘Space` | Unicode 字符输入 |
| `` ⌘` `` | 在多个 OS 窗口间循环 |
| `⌘H` / `⌘M` / `⌘Q` | 隐藏 / 最小化 / 退出 |

---

## 4. 常用功能详解

### 分屏(原生)

1. 新建分屏:`⌘↩` 或 `⌃⇧↩`(在 `splits` 布局下会把当前窗口一分为二)。
2. 窗口间切换:`⌃⇧]` / `⌃⇧[`(循环切换)。
3. 切换布局:`⌃⇧L` 在全部 7 种布局间循环(见上方布局表)。
4. 调整分屏大小:`⌃⇧R` 进入 resize 模式,或(0.46+)**直接用鼠标拖窗口边框**。
5. 把当前窗口移到最前:`` ⌃⇧` ``。
6. 关闭某个分屏:`⇧⌘D`。

> 已移除自定义的 tmux 式分屏键,改用 kitty 原生。若想要「按方向跳 / 指定左右上下分屏」,
> 那些需要自定义 `map`(`neighboring_window`、`launch --location=vsplit/hsplit`),原生默认不绑定。

### 查看历史输出

- 快速滚动:`⌘↑/↓`、`⌘PageUp/PageDown`。
- 深度浏览:`⌃⇧H` 把整段历史丢进 `less`,可搜索、可复制。
- 只看上条命令输出:`⌃⇧G`(依赖 shell 集成,zsh 默认开启)。

### 选 URL / 路径(hints kitten)

按 `⌃⇧E`,屏幕上所有 URL 会标上字母,按对应字母即用浏览器打开。
还能选路径、行号等(`kitten hints` 可定制)。

### 命令完成通知

你启用了 `notify_on_cmd_finish unfocused 15.0`:
当某条命令运行超过 15 秒、且 kitty 窗口此刻**没有聚焦**时,完成后弹系统通知。

### 远程控制(脚本化 kitty)

你已开启 `allow_remote_control socket-only` + `listen_on unix:/tmp/mykitty`,可在终端里用:

```bash
kitty @ --to unix:/tmp/mykitty ls               # 列出所有窗口/标签的 JSON
kitty @ --to unix:/tmp/mykitty launch --type=tab # 新开标签页
kitty @ --to unix:/tmp/mykitty set-colors -a background=#000000
kitty @ --to unix:/tmp/mykitty load-config       # 重载配置
```

> ⚠️ socket 只在「通过该配置启动的 kitty 实例」里存在;在别的进程里连会报 `no such file`。

---

## 5. 你当前启用的配置说明

| 配置项 | 值 | 作用 |
|---|---|---|
| `font_family` | Maple Mono NF CN | 等宽 + Nerd Font 图标 |
| `font_size` | 18 | 字号 |
| `background_opacity` | 0.9 | 背景透明 |
| `background_blur` | 64 | 毛玻璃模糊(配合透明) |
| `hide_window_decorations` | titlebar-only | 隐藏标题栏 |
| `window_padding_width` | 5 | 内容到边缘的内边距 |
| `window_margin_width` | 2 | 窗口外边距 |
| `tab_bar_edge` | bottom | 标签栏在底部 |
| `tab_bar_style` | powerline | Powerline 尖角 |
| `tab_powerline_style` | angled | Powerline 尖角样式 |
| `tab_title_template` | {index}: {title} | 标签标题格式 |
| `active_tab_font_style` | bold | 当前标签加粗 |
| `tab_activity_symbol` | ● | 后台标签有输出时标记 |
| `cursor_trail` | 1 | 光标移动残影 |
| `cursor_trail_decay` | 0.2 0.6 | 拖尾快进慢出 |
| `cursor_shape` | block | 方块光标 |
| `cursor_blink_interval` | 0 | 光标不闪烁 |
| `shell_integration` | no-cursor | 关掉 shell 集成强制改写光标(否则提示符变竖线) |
| `disable_ligatures` | cursor | 连字保留、光标处拆开 |
| `macos_option_as_alt` | yes | Option 当 Alt 用(⌥ 不再打特殊符号) |
| `macos_thicken_font` | 0.4 | Retina 字体加粗描边 |
| `scrollback_lines` | 20000 | 回滚历史行数 |
| `copy_on_select` | clipboard | 选中即复制 |
| `clipboard_control` | write-clipboard write-primary no-ask | 写剪贴板/primary 不弹确认 |
| `confirm_os_window_close` | 0 | 关窗不弹确认 |
| `enable_audio_bell` | no | 静音提示音 |
| `url_style` | curly | URL 波浪下划线 |
| `inactive_text_alpha` | 0.7 | 失焦分屏自动变暗 |
| `visual_bell_duration` | 0.25 ease-in-out | 出错时整屏柔和闪光(带缓动) |
| `visual_bell_color` | #bb9af7 | 视觉响铃闪光颜色 |
| `modify_font` | cell_height 112% | 行高 +12%,排版更透气 |
| `enabled_layouts` | * | 启用全部 7 种布局(kitty 默认) |
| `sync_to_monitor` | no | 不等垂直同步,降低输入延迟 |
| `repaint_delay` | 2 | 重绘间隔 2ms,更跟手 |
| `wheel_scroll_multiplier` | 3.0 | 鼠标滚轮一格滚更多行 |

---

## 6. 修改 & 重载配置

1. 编辑 `~/.config/kitty/kitty.conf`(或按 `⌘,`)。
2. 保存后按 `⌃⌘,` 重载,**无需重启**。
3. **注意:kitty 不支持行尾注释**——`#` 注释必须独立成行:

   ```conf
   # 正确:注释单独一行
   scrollback_lines 20000
   ```

   写成 `scrollback_lines 20000   # 注释` 会把 `20000 # 注释` 当成整数解析而报错。
4. 主题文件:`dark-theme.auto.conf` / `light-theme.auto.conf`(Tokyo Night,跟随系统深浅色自动切换)。

---

## 7. 酷炫功能 & kitten 速查

### 开箱即用的命令(直接在终端敲)

| 命令 | 作用 |
|---|---|
| `kitten icat 图片.png` | 终端内直接显示图片(yazi 预览就靠它) |
| `kitten diff 文件A 文件B` | 语法高亮的并排 diff,可滚动、能 diff 图片 |
| `kitten themes` | 几百个主题实时预览,回车应用 |
| `kitten broadcast` | 一处输入广播到所有分屏(多服务器神器) |
| `kitten ssh 主机` | 增强版 ssh,自动把 terminfo + shell 集成推到远端 |

### marks 高亮(已配快捷键)

- `⌃⇧M`:输入要高亮的文字 → 屏幕上所有匹配处高亮。
- `⌃⇧⌥M`:清除高亮。
- 常驻高亮(自己加键即可):`map ctrl+shift+y toggle_marker itext 1 error`
  - 类型:`itext`=大小写不敏感纯文本,`text`=区分大小写,`regex`/`iregex`=正则;颜色 `1/2/3`。

### 动态透明度(已开启)

按 `⌃⇧A`,再按:

- `M` 提高不透明度(+0.1) · `L` 降低(−0.1)
- `1` 完全不透明 · `D` 恢复默认

### Quake 下拉终端

配置已写好:`~/.config/kitty/quick-access-terminal.conf`(顶部下拉 / 25 行 / 失焦自动隐藏)。
呼出/收起命令:

```bash
/Applications/kitty.app/Contents/MacOS/kitten quick-access-terminal
```

> macOS 没有「命令绑全局热键」的原生能力,需借助工具给它绑一个全局快捷键(如 `⌥Space`):
>
> - **Raycast**:新建 Script Command 跑该命令并设 Hotkey;
> - **skhd**:`alt - space : /Applications/kitty.app/Contents/MacOS/kitten quick-access-terminal`;
> - **Shortcuts.app**:新建快捷指令 →「运行 Shell 脚本」填该命令 → 分配键盘快捷键。

---

## 8. 新版本特性(kitty 0.45 → 0.47)

本机已升级到 **0.47.4**,以下是相对旧版(0.44)值得一用的新能力。

### 鼠标操作(0.46 / 0.47,开箱即用)

| 操作 | 作用 | 引入版本 |
|---|---|---|
| 拖拽标签页 | 重排 / 移到另一个 OS 窗口 / 拖出独立 | 0.46 |
| 双击标签页 | 重命名该标签 | 0.46 |
| 拖拽窗口边框 | 在任意布局下调整分屏大小 | 0.46 |
| 拖放窗口本体 | 重排分屏 / 移到别的标签 / 拖出独立 | 0.47 |

> `focus_follows_mouse` 行为在 0.47 改进:只在鼠标**进入另一个窗口**时切换焦点,不再随每次鼠标移动抖动。

### 滚动(0.46 / 0.47)

- **平滑滚动成为默认**:0.47 起 `scroll_line_up` / `scroll_line_down`(即 `⌘↑` / `⌘↓`)默认平滑滚动。想要回到逐行硬跳,重新 `map` 时去掉 `smooth` 参数即可。
- **像素级 / 动量滚动**:0.46 新增 `pixel_scroll`、`momentum_scroll`(动量滚动主要惠及 Linux 触控板;macOS 触控板本身已是惯性滚动)。

### 分屏增强(0.47)

- `equalize` 动作 + `equalize_on_close` 选项:关闭某个分屏后,把剩余空间**按比例重新均分**。开启示例(单独成行):

  ```conf
  equalize_on_close yes
  ```

### 这些新特性在 0.47.4 已**默认开启**(无需配置)

| 配置项 | 默认值 | 作用 / 如何改 |
|---|---|---|
| `auto_reload_config` | `0.1` | 改完配置**自动重载**(0.1s 防抖),已无需手动 `⌃⌘,`。值为秒数,负数关闭。 |
| `progress_bar` | `top` | 程序发 `OSC 9;4` 报告进度时在顶部画进度条。可改 `left`/`right`/`bottom`/`hidden`。 |
| `macos_dock_badge_on_bell` | `yes` | 响铃且 kitty 失焦时 Dock 图标显示角标(回到焦点自动清除)。 |

### 需手动开启的(非默认)

| 配置项 | 作用 | 可选值 |
|---|---|---|
| `palette_generate` | 填充 256 色板里未设(`none`)的颜色 | `fixed`(默认/传统)· `legacy` · `semantic`(光主题可读性更好,但会改变部分颜色含义) |

> 命令面板 `⌃⇧F3`(0.46 引入)已在第 3 节列出 —— 搜索并触发任意动作,含未绑定快捷键的动作。

---

## 9. 官方文档参考

- 总览 / 核心概念:<https://sw.kovidgoyal.net/kitty/overview/>
- 全部配置项:<https://sw.kovidgoyal.net/kitty/conf/>
- 快捷键 / 动作(actions):<https://sw.kovidgoyal.net/kitty/actions/>
- 布局 layouts:<https://sw.kovidgoyal.net/kitty/layouts/>
- 远程控制 `kitty @`:<https://sw.kovidgoyal.net/kitty/remote-control/>
- 性能调优:<https://sw.kovidgoyal.net/kitty/performance/>
- kittens(扩展工具):<https://sw.kovidgoyal.net/kitty/kittens/>
- 更新日志(各版本新特性):<https://sw.kovidgoyal.net/kitty/changelog/>
