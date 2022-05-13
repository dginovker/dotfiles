# Only run if we're running on Ubuntu
if lsb_release -a 2> /dev/null | grep -q Ubuntu ; then
  alias yay="yes Y | sudo apt-get update ; yes Y | sudo apt-get upgrade ; yes Y | sudo apt autoremove ; flatpak update -y"
fi

