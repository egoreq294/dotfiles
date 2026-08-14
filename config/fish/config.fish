if status is-interactive
    # Commands to run in interactive sessions can go here

    # Настройка Go
    set -x GOPATH $HOME/.cache/go
    set -x GOCACHE $HOME/.cache/go-build

    # Выключаем стандартное приветствие
    # set -g fish_greeting "fastfetch"

    function fish_greeting
        if command -q fastfetch
            fastfetch
        end
    end

    alias ls='eza -al --color=always --group-directories-first' # my preferred listing
    alias la='eza -a --color=always --group-directories-first' # all files and dirs
    alias ll='eza -l --color=always --group-directories-first' # long format
    alias lt='eza -aT --color=always --group-directories-first' # tree listing
    alias l.='eza -a | egrep "^\."'
    alias l.='eza -al --color=always --group-directories-first ../' # ls on the PARENT directory
    alias l..='eza -al --color=always --group-directories-first ../../' # ls on directory 2 levels up
    alias l...='eza -al --color=always --group-directories-first ../../../' # ls on directory 3 levels up

    alias restart-audio='systemctl --user restart wireplumber pipewire pipewire-pulse'

    alias v="nvim"
    # anthropic vars
    set -gx ANTHROPIC_BASE_URL "https://agentrouter.org/"
    set -gx ANTHROPIC_AUTH_TOKEN sk-gQd0Ms61FrP8HzUs9AJbH19uneYwob9vkqEJx8u86oCtoLbE
    set -gx ANTHROPIC_MODEL claude-opus-4-6

    # http proxy for terminal
    set -gx http_proxy http://127.0.0.1:10808
    set -gx https_proxy http://127.0.0.1:10808

end
set -gx PATH $HOME/.local/bin $PATH
