# fox-mini.zsh-theme
# Fox-derived two-line frame prompt. Colors via ANSI names so the theme
# inherits the terminal's active palette.
#
# Line 1: ┌─[user]─(cwd)─( branch ✓)
# Line 2: └[exit] ->     (exit block only when last command failed)
#
# Path truncates to last 3 segments with leading ellipsis past 4 deep.
# Requires a Nerd Font (for the  branch glyph).
# oh-my-zsh enables PROMPT_SUBST, so $(git_prompt_info) re-evaluates per redraw.

PROMPT='%F{cyan}┌─[%B%F{white}%n%b%F{cyan}]─(%F{magenta}%(5~.…/%3~.%~)%F{cyan})$(git_prompt_info)
%F{cyan}└%(?..%F{red}[%?] %F{cyan})->%f '

ZSH_THEME_GIT_PROMPT_PREFIX="%F{cyan}─(%F{yellow} "
ZSH_THEME_GIT_PROMPT_SUFFIX="%F{cyan})%f"
ZSH_THEME_GIT_PROMPT_DIRTY=" %F{red}✗"
ZSH_THEME_GIT_PROMPT_CLEAN=" %F{green}✓"
