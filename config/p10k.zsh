# ~/.p10k.zsh — Minimal Red Theme
# Benötigt eine Nerd Font im Terminal.
#
#   ╭─   ~/projekt   main  3s  1
#   ╰─❯
#
# Git, venv, Jobs, Laufzeit und Exit-Code erscheinen nur, wenn relevant.

'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'
  [[ $ZSH_VERSION == (5.<1->*|<6->.*) ]] || return

  # ─── Segmente ────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    os_icon                 # Arch-Logo
    dir                     # Pfad (ohne Icon)
    vcs                     # nur in Git-Repos
    virtualenv              # nur in aktiver Python-venv
    background_jobs         # nur wenn Jobs laufen
    command_execution_time  # nur wenn Befehl > 3s
    status                  # nur bei Fehler
    newline
    prompt_char
  )
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()

  # ─── Allgemein ───────────────────────────────────────────────
  typeset -g POWERLEVEL9K_MODE=nerdfont-complete
  typeset -g POWERLEVEL9K_ICON_PADDING=moderate
  typeset -g POWERLEVEL9K_ICON_BEFORE_CONTENT=true
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
  typeset -g POWERLEVEL9K_BACKGROUND=
  typeset -g POWERLEVEL9K_FOREGROUND=160

  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_PROMPT_FIRST_SEGMENT_START_SYMBOL=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_PROMPT_LAST_SEGMENT_END_SYMBOL=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=

  # ─── Rahmen ──────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX='%160F╭─ '
  typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX='%160F├─ '
  typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='%160F╰─'
  typeset -g POWERLEVEL9K_MULTILINE_{FIRST,NEWLINE,LAST}_PROMPT_SUFFIX=
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR=' '

  # ─── OS-Icon (Arch-Logo) ─────────────────────────────────────
  typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND=196
  typeset -g POWERLEVEL9K_OS_ICON_RIGHT_WHITESPACE=' '   # extra Leerzeichen vor dem Pfad

  # ─── Verzeichnis (voller Pfad, kein Icon) ────────────────────
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=203
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=203
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=
  typeset -g POWERLEVEL9K_DIR_SHOW_WRITABLE=v3
  typeset -g POWERLEVEL9K_DIR_VISUAL_IDENTIFIER_EXPANSION=
  # In ~ (/home/leon) den Pfad komplett ausblenden
  typeset -g POWERLEVEL9K_DIR_HOME_CONTENT_EXPANSION=
  typeset -g POWERLEVEL9K_DIR_HOME_VISUAL_IDENTIFIER_EXPANSION=
  typeset -g POWERLEVEL9K_DIR_NOT_WRITABLE_VISUAL_IDENTIFIER_EXPANSION=$'\uf023' #  nur wenn schreibgeschützt

  # ─── Git ─────────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=$'\uf126 '                           # 
  typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_EXPANSION=
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=160
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=226
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=217
  typeset -g POWERLEVEL9K_VCS_CONFLICTED_FOREGROUND=196
  typeset -g POWERLEVEL9K_VCS_LOADING_FOREGROUND=244

  # ─── Python venv ─────────────────────────────────────────────
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=167
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=
  typeset -g POWERLEVEL9K_VIRTUALENV_VISUAL_IDENTIFIER_EXPANSION=$'\ue73c'     # 

  # ─── Hintergrund-Jobs ────────────────────────────────────────
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=217
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=true
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VISUAL_IDENTIFIER_EXPANSION=$'\uf013' # 

  # ─── Laufzeit des letzten Befehls ────────────────────────────
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=167
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_VISUAL_IDENTIFIER_EXPANSION=$'\uf252' # 

  # ─── Exit-Status (nur bei Fehler) ────────────────────────────
  typeset -g POWERLEVEL9K_STATUS_OK=false
  typeset -g POWERLEVEL9K_STATUS_ERROR=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=196
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION=$'\uf00d'   # 

  # ─── Prompt-Zeichen (rot, gelb nach Fehler) ──────────────────
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=196
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=226
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='V'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIOWR_CONTENT_EXPANSION='▶'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=true

  # ─── Sonstiges ───────────────────────────────────────────────
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true

  (( ! $+functions[p10k] )) || p10k reload
}

typeset -g POWERLEVEL9K_CONFIG_FILE=${${(%):-%x}:a}
(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'
