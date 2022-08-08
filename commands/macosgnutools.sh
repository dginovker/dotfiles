# Only run if we're running on MacOS
if uname 2> /dev/null | grep -q Darwin ; then
  PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
fi
