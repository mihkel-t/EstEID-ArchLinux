#!/bin/bash
#  Written by Mihkel Tõnnov <mihhkel at gmail com>, 14 Oct 2020
# 8 Jun 2022: replaced chrome-token-signing & esteidpkcs11loader with web-eid

# key="90C0B5E75C3B195D" # For chrome-token-signing
# gpg --list-keys $key > /dev/null 2>&1 || gpg --keyserver keyserver.ubuntu.com --recv-key $key # Raul Metsma

wget -q -O- https://github.com/mrts.gpg | gpg --import - # For web-eid; Mart Sõmermaa

cd AURs
for pkg in xml-security-c libdigidocpp qdigidoc4 web-eid; do # chrome-token-signing esteidpkcs11loader
  # Will be built & installed in that order
  echo -e "\n# Now starting: $pkg\n"
  mkdir $pkg 2>/dev/null
  cd $pkg
  [[ -d .git ]] && git pull || git clone https://aur.archlinux.org/$pkg.git .
  makepkg -si
  cd ..
done

cd ..

if [[ $(systemctl is-enabled pcscd.socket) == 'disabled' ]]; then
  echo "Enabling PCSCd..."
  sudo systemctl enable --now pcscd.socket
fi

echo -e "\n # Checking if there's anything to remove/clean..."

# Post-install (was needed with chrome-token-signing / esteidpkcs11loader)
# read -p "Run first-time setup? [y/N] " firstrun
# if [[ $firstrun == y ]]; then
    # To enable PIN 1 authentication in Google Chrome and Chromium
#   sudo modutil -dbdir sql:$HOME/.pki/nssdb -add opensc-pkcs11 -libfile onepin-opensc-pkcs11.so -mechanisms FRIENDLY
    # For new cards issued since December 2018; apparently has been unnecessary after Jun 2019
    # sudo modutil -force -dbdir sql:$HOME/.pki/nssdb -add idemia-pkcs11 -libfile /usr/local/AWP/lib/libOcsPKCS11Wrapper.so -mechanisms FRIENDLY
# fi

# If present, remove the old packages
toberemoved=$(pacman -Q | grep -E '^(chrome-token-signing|esteidpkcs11loader|awp-blob) ' | cut -f 1 -d ' ' | tr '\n' ' ')
[[ $toberemoved ]] && sudo pacman -R --noconfirm $toberemoved
# Clean up ~/.pki/nssdb
[[ $(sudo modutil -dbdir sql:$HOME/.pki/nssdb -rawlist | grep -E ' name="(idemia|opensc)-pkcs11" ') ]] && {
  sudo modutil -dbdir sql:$HOME/.pki/nssdb -delete idemia-pkcs11
  sudo modutil -dbdir sql:$HOME/.pki/nssdb -delete opensc-pkcs11
}

echo -e "\n# All done! Remember to also install the Web-eID extension for your browser.\n"
