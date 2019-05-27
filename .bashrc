#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
PS1='\[\e[1;91m\]\u@\h: \[\e[33m\]\W \[\e[32m\]\$ \[\033[0m\]'

alias ls='ls --color=auto'

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

NORMAL=`echo -e '\033[0m'`
RED=`echo -e '\e[1;91m'`
GREEN=`echo -e '\e[32m'`
LGREEN=`echo -e '\033[1;32m'`
BLUE=`echo -e '\033[0;34m'`
LBLUE=`echo -e '\033[1;34m'`
YELLOW=`echo -e '\e[33m'`
MAGENTA=`echo -e '\033[0;95m'`
IP4=$LGREEN
IP6=$MAGENTA
IFACE=$YELLOW
DEFAULT_ROUTE=$LBLUE
IP_CMD=$(which ifconfig)

function colored_ip(){
  ${IP_CMD} $@ | sed \
    -e "s/inet [^ ]\+ /${IP4}&${RED}/g"\
    -e "s/ether [^ ]\+ /${RED}&${NORMAL}/g"\
    -e "s/netmask [^ ]\+ /${LBLUE}&${NORMAL}/g"\
    -e "s/broadcast [^ ]\+ /${MAGENTA}&${NORMAL}/g"\
    -e "s/^default via .*$/${DEFAULT_ROUTE}&${NORMAL}/"\
    -e "s/^\([0-9]\+: \+\)\([^ \t]\+\)/\1${IFACE}\2${NORMAL}/"
}

alias ifconfig='colored_ip'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias vi=vim
alias convert_to_haml="find . -name \*.erb -print | sed 'p;s/.erb$/.haml/' | xargs -n2 html2haml"
if [ $UID -ne 0 ]; then
  alias reboot='sudo reboot'
  alias update='sudo pacman -Syyu'
  alias svim='sudo vim'
  alias apache_start='sudo systemctl start httpd.service'
  alias apache_stop='sudo systemctl stop httpd.service'
  alias ports='sudo netstat -antp'
  alias tor_start='sudo systemctl start tor.service'
  alias tor_stop='sudo systemctl stop tor.service'
  alias orphaned_packets='sudo pacman -Qdt'
  alias rules='sudo ufw status verbose'
  alias kern-log='journalctl -k --since "20 min ago"'
  alias kern-make='make -C /lib/modules/$(uname -r)/build M=$PWD modules'
  alias kern-clean='make -C /lib/modules/$(uname -r)/build M=$PWD clean'
  alias devices='cat /proc/devices'
fi

export VULKAN_SDK=/home/vince/Downloads/1.1.106.0/x86_64
export PATH=$VULKAN_SDK/bin:$PATH
export LD_LIBRARY_PATH=$VULKAN_SDK/lib:$LD_LIBRARY_PATH
export VK_LAYER_PATH=$VULKAN_SDK/etc/explicit_layer.d
