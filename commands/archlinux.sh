# Only run if we're running on Arch Linux
if cat /etc/*-release | grep -q "Arch Linux" ; then
  set_new_sha256_and_install_virtualbox_ext_oracle(){
    cd /tmp; wget https://aur.archlinux.org/cgit/aur.git/snapshot/virtualbox-ext-oracle.tar.gz
    tar xvf virtualbox-ext-oracle.tar.gz
    cd virtualbox-ext-oracle/
    source PKGBUILD
    wget $source
    NEWSHA256=$(sha256sum *vbox-extpack|awk {'print $1'})
    Line=$(printf "sha256sums=('"$NEWSHA256"')")
    sed -i "s/sha256sums.*/$Line/g" PKGBUILD
    makepkg -sc
    sudo pacman -U *.pkg.tar.zst
  }
fi


