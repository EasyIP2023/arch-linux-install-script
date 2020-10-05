#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
PS1='\[\e[1;91m\]\u@\h: \[\e[33m\]\W \[\e[32m\]\$ \[\033[0m\]'

NORMAL=`echo -e '\x1b[0m'`
RED=`echo -e '\x1B[31;1m'`
LGREEN=`echo -e '\033[1;32m'`
IBLUE=`echo -e '\x1B[30;1m'`
LBLUE=`echo -e '\033[1;34m'`
YELLOW=`echo -e '\x1B[33;1m'`
MAGENTA=`echo -e '\e[37;1m'`
IP_CMD=$(which ifconfig)

function colored_ip(){
  ${IP_CMD} $@ | sed \
    -e "s/inet [^ ]\+ /${LGREEN}&${NORMAL}/g"\
    -e "s/ether [^ ]\+ /${RED}&${NORMAL}/g"\
    -e "s/netmask [^ ]\+ /${LBLUE}&${NORMAL}/g"\
    -e "s/broadcast [^ ]\+ /${IBLUE}&${NORMAL}/g"\
    -e "s/^default via .*$/${YELLOW}&${NORMAL}/g"\
    -e "s/^\([0-9]\+: \+\)\([^ \t]\+\)/\1${MAGENTA}\2${NORMAL}/g"
}

alias ls='ls --color=auto'
alias ifconfig='colored_ip'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias vi='vim'
alias convert_to_haml="find . -name \*.erb -print | sed 'p;s/.erb$/.haml/' | xargs -n2 html2haml"
if [ $UID -ne 0 ]; then
  alias reboot='sudo reboot'
  alias update='sudo pacman -Syyu && yay -Sc --noconfirm'
  alias svim='sudo vim'
  alias apache_start='sudo systemctl start httpd.service'
  alias apache_stop='sudo systemctl stop httpd.service'
  alias ports='sudo netstat -antp'
  alias tor_start='sudo systemctl start tor.service'
  alias tor_stop='sudo systemctl stop tor.service'
  alias orphaned_packets='sudo pacman -Qdt'
  alias rm_orphaned_packets='sudo pacman -Rns $(pacman -Qtdq)'
  alias rules='sudo ufw status verbose'
  alias kern-log='journalctl -k --since "20 min ago"'
  alias kern-make='make -C /lib/modules/$(uname -r)/build M=$PWD modules'
  alias kern-clean='make -C /lib/modules/$(uname -r)/build M=$PWD clean'
  alias devices='cat /proc/devices'
fi

WB_SOS=$HOME/storage/steam/steamapps/common/MountBlade\ Warband
LIB_X86_STEAM_RUNTIME=/home/vince/.local/share/Steam/ubuntu12_32/steam-runtime/usr/lib/x86_64-linux-gnu
LIB_X86_STEAM=/home/vince/.local/share/Steam/ubuntu12_32/steam-runtime/lib/x86_64-linux-gnu/
export LD_LIBRARY_PATH=/usr/lib:/usr/local/lib:$WB_SOS:$LIB_X86_STEAM_RUNTIME:$LIB_X86_STEAM

LUC_IBUILD=$HOME/storage/git/syfyme/lucurious/ibuild
alias luc_install='sudo ninja install -C $LUC_IBUILD'
alias luc_uninstall='sudo ninja uninstall -C $LUC_IBUILD'
alias bat='upower -i /org/freedesktop/UPower/devices/battery_BAT0| grep -E "state|to full|percentage"'
alias disk_mem='df -h /dev/mapper/r00t && echo && df -h /dev/mapper/storage'

dev_file=/dev/$(lsblk -r -o name,fstype | grep crypto_LUKS | grep -v nvme | awk '{printf $1}')
alias open_drive='sudo cryptsetup open --verbose --type luks $dev_file storage && sudo mount -v /dev/mapper/storage $HOME/storage'
alias close_drive='sudo umount -v $HOME/storage && sudo cryptsetup --verbose close storage'
#alias valgrind='valgrind --tool=memcheck --leak-check=full --show-leak-kinds=all --undef-value-errors=no --trace-children=yes'
alias git-diff='git diff --cached'
alias gpg_recv_keys='gpg2 --keyserver pool.sks-keyservers.net --recv-keys'

export RUBYOPT='-W:no-deprecated -W:no-experimental'
# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin:$HOME/.rvm/rubies/ruby-2.7.0/bin"
