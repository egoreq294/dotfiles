if status is-interactive
    # Commands to run in interactive sessions can go here

    # Настройка Go
    set -x GOPATH $HOME/.cache/go
    set -x GOCACHE $HOME/.cache/go-build

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

    # HTTP proxy for local machine only
    if not set -q SSH_TTY
        set -gx http_proxy http://127.0.0.1:10808
        set -gx https_proxy http://127.0.0.1:10808
    end

    set -gx EDITOR nvim
    set -gx VISUAL nvim

end
set -gx PATH $HOME/.local/bin $PATH
