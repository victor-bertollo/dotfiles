if status is-interactive
    # Commands to run in interactive sessions can go here
end

if status is-login
    if uwsm check may-start
        exec uwsm start hyprland.desktop
    end
end

set -g fish_greeting
set -g TERM xterm-256color
starship init fish | source

# ZVM
set -gx ZVM_INSTALL "$HOME/.zvm/self"
set -gx PATH $PATH "$HOME/.zvm/bin"
set -gx PATH $PATH "$ZVM_INSTALL/"
