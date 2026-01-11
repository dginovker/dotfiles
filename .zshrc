# If you come from bash you might have to change your $PATH.
export PATH="$HOME/.local/bin:$PATH"

DISABLE_AUTO_UPDATE=true

# Path to your oh-my-zsh installation.
[ -d "/Users/$USER/.oh-my-zsh" ] && export ZSH="/Users/$USER/.oh-my-zsh"
[ -d "/home/$USER/.oh-my-zsh" ] && export ZSH="/home/$USER/.oh-my-zsh"
[ -d "/usr/share/oh-my-zsh" ] && export ZSH="/usr/share/oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME

ZSH_THEME="af-magic";

for f in ~/Projects/dotfiles/commands/*; do source $f; done

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  fast-syntax-highlighting
  zsh-autocomplete
)

[ -d "$ZSH" ] && source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

alias pb=pbpaste

unalias gcp 2>/dev/null
gcp () {
  git commit -m "$*"
  git push
}

gpa () {
  git add *
  git commit -m "$*"
  git push
}

# Adds and pushes all .cs files with a commit message
# Usage:
# gpcs Rename all banana => apples
gpcs () {
  git add "**/*.cs" 2>/dev/null
  git add "**/*.java" 2>/dev/null
  git add "**/*.js" 2>/dev/null
  git add "**/*.kt" 2>/dev/null
  git commit -m "$*"
  git push
}

# Kill all processes with a name
hurt () {
  ps aux | grep -ie "$*" | awk '{print $2}' | xargs kill -9 
}

# Lazy typing
gs () {
  git status
}

# Show all changes in .cs files (useful before gpcs)
gdcs () {
  git diff -w "**/*.cs" "**/*.java" "**/*.js" "**/*.kt"
}

# Show all committed changes (lazy typing)
gdc () {
  git diff --cached -w
}

# Make a QR code of a link
qrcode () {
  qrencode -t ansiutf8 "$*"
}

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export GOOGLE_APPLICATION_CREDENTIALS="/home/$USER/.config/gcloud/application_default_credentials.json"

if command -v pyenv &> /dev/null
then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

# Claude Code configuration
mkdir -p ~/.claude
ln -sfn ~/Projects/dotfiles/claude/agents ~/.claude/agents
ln -sfn ~/Projects/dotfiles/claude/commands ~/.claude/commands
ln -sfn ~/Projects/dotfiles/claude/skills ~/.claude/skills

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/opt/gcloudcli/google-cloud-sdk/path.zsh.inc' ]; then . '/opt/gcloudcli/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/opt/gcloudcli/google-cloud-sdk/completion.zsh.inc' ]; then . '/opt/gcloudcli/google-cloud-sdk/completion.zsh.inc'; fi
