#shellcheck shell=sh disable=SC2004,SC2016

# shellcheck source=lib/libexec.sh
. "${SHELLSPEC_LIB:-./lib}/libexec.sh"
use reset_params
load binary

read_dot_file() {
  [ "$1" ] || return 0
  [ -e "$1/$2" ] || return 0
  file="$1/$2" parser=$3
  set --
  while IFS= read -r line || [ "$line" ]; do
    if [ $# -eq 0 ]; then
      eval "set -- $line"
    else
      eval "set -- \"\$@\" $line"
    fi
  done < "$file" &&:
  [ $# -eq 0 ] || "$parser" "$@"
}

read_cmdline() {
  [ -e "$1" ] || return 0

  octal_dump < "$1" | {
    cmdline='' printf_octal_bug=''
    [ "$(printf '\101' 2>/dev/null ||:)" = "A" ] || printf_octal_bug=0
    while IFS= read -r line; do
      case $line in
        000) line="040" ;;
        1??) line="$printf_octal_bug$line" ;;
      esac
      cmdline="$cmdline\\$line"
    done
    #shellcheck disable=SC2059
    printf "$cmdline"
  }
}

read_ps() {
  #shellcheck disable=SC2015
  ps -f 2>/dev/null | {
    IFS=" " pid=$1 p=0 c=0 _pid=''
    IFS= read -r line
    reset_params '$line'
    eval "$RESET_PARAMS"

    for name in "${@:-}"; do
      p=$(($p + 1))
      case $name in ([pP][iI][dD]) break; esac
    done

    for name in "${@:-}"; do
      case $name in ([cC][mM][dD] | [cC][oO][mM][mM][aA][nN][dD]) break; esac
      c=$(($c + 1))
    done

    while IFS= read -r line; do
      eval "$RESET_PARAMS"
      eval "_pid=\${$p:-}"
      [ "$_pid" = "$pid" ] && shift $c && line="$*" && break
    done

    # workaround for old busybox ps format
    case $line in (\{*) line=${line#*\} }; esac

    echo "$line"
  } &&: ||:
}

current_shell() {
  self=$1 pid=$2

  cmdline=$(read_cmdline "/proc/$2/cmdline")
  if [ -z "$cmdline" ]; then
    cmdline=$(read_ps "$2")
  fi

  echo "${cmdline%% $self*}"
}

command_path() {
  case $1 in
    */*) [ -x "${1%% *}" ] && echo "$1" && return 0 ;;
    *)
      command=$1
      reset_params '$PATH' ':'
      eval "$RESET_PARAMS"
      while [ $# -gt 0 ]; do
        [ -x "${1%/}/${command%% *}" ] && echo "${1%/}/$command" && return 0
        shift
      done
  esac
  return 1
}

check_range() {
  reset_params '$1' ':'
  eval "$RESET_PARAMS"
  while [ $# -gt 0 ]; do
    case $1 in
      @*) case ${1#@} in (*[!0-9-]*) return 1; esac ;;
      *) case $1 in (*[!0-9]*) return 1; esac ;;
    esac
    shift
  done
  return 0
}
