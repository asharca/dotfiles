#!/usr/bin/env zsh
# ZSH Options

# 使用 Emacs 键绑定模式
bindkey -e

# 自动 cd（输入目录名即可进入）
setopt AUTO_CD

# 更正拼写错误
setopt CORRECT

# 后台任务以较低优先级运行
setopt NO_BG_NICE

# 后台任务结束时不显示状态报告
setopt NO_CHECK_JOBS

# 退出时不杀死后台任务
setopt NO_HUP
