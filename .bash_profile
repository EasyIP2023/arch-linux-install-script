#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
export YKPERS_LIBS='-L/usr/local/lib/libykpers-1.a'
export YKPERS_CFLAGS='-I/usr/local/include/ykpers-1'

