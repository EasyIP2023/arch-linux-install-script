#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
PS1='\[\e[1;91m\]\u@\h: \[\e[33m\]\W \[\e[32m\]\$ \[\033[0m\]'

alias ls='ls --color=auto'

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
alias ls='ls -l --color=auto'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias vi=vim
alias convert_to_haml="find . -name \*.erb -print | sed 'p;s/.erb$/.haml/' | xargs -n2 html2haml"
if [ $UID -ne 0 ]; then
  alias reboot='sudo reboot'
  alias update='sudo pacman -Syyu &&6 yay -Sc'
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
alias man_perlpod='man perlpod'

export VULKAN_SDK=$HOME/storage/Downloads/1.1.130.0/x86_64
export PATH=$PATH:$VULKAN_SDK/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$VULKAN_SDK/lib
export VK_LAYER_PATH=$VULKAN_SDK/etc/vulkan/explicit_layer.d
export SDL_VIDEODRIVER=wayland

alias luc_install='sudo ninja install -C $HOME/storage/git/lucurious/ibuild'
alias luc_uninstall='sudo ninja uninstall -C $HOME/storage/git/lucurious/ibuild'
alias bat='upower -i /org/freedesktop/UPower/devices/battery_BAT0| grep -E "state|to full|percentage"'
alias disk_mem='df -h /dev/mapper/r00t && df -h /dev/mapper/storage'
alias open_drive='sudo cryptsetup open --verbose --type luks /dev/sda1 storage && sudo mount -v /dev/mapper/storage storage'
alias close_drive='sudo umount -Rv storage && sudo cryptsetup --verbose close storage'
