#!/bin/bash
#  Written by Mihkel Tõnnov <mihhkel at gmail com>, 14 Oct 2020

key="90C0B5E75C3B195D" # For chrome-token-signing
gpg --list-keys $key > /dev/null 2>&1 || gpg --keyserver keyserver.ubuntu.com --recv-key $key # Raul Metsma

cd AURs
for pkg in xml-security-c libdigidocpp qdigidoc4 chrome-token-signing esteidpkcs11loader; do
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
  echo # An empty line
fi

# Post-install
read -p "Run first-time setup? [y/N] " firstrun
if [[ $firstrun == y ]]; then
  # To enable PIN 1 authentication in Google Chrome and Chromium
  sudo modutil -dbdir sql:$HOME/.pki/nssdb -add opensc-pkcs11 -libfile onepin-opensc-pkcs11.so -mechanisms FRIENDLY
  # For new cards issued since December 2018
  sudo modutil -force -dbdir sql:$HOME/.pki/nssdb -add idemia-pkcs11 -libfile /usr/local/AWP/lib/libOcsPKCS11Wrapper.so -mechanisms FRIENDLY
fi
