# Use NixOS 23.05 for glibc 2.37 compatibility with Debian 12+ and Ubuntu 22.04+
{ pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-23.05.tar.gz";
    sha256 = "05cbl1k193c9la9xhlz4y6y8ijpb2mkaqrab30zij6z4kqgclsrd";
  }) {} }:

pkgs.stdenv.mkDerivation rec {
  pname = "nbd";
  version = "3.26.1";

  src = ./.;

  nativeBuildInputs = with pkgs; [
    autoreconfHook
    pkg-config
    flex
    bison
    autoconf-archive
  ];

  buildInputs = with pkgs; [
    glib
    gnutls
    libnl
    linuxHeaders
  ];

  # Ensure version is set correctly without git
  # We need to set VERSION before autoreconf runs
  postPatch = ''
    # Create a static version file since git won't be available in the sandbox
    echo "${version}" > support/VERSION

    # Patch genver.sh to use the VERSION file if git is not available
    cat > support/genver.sh << 'EOF'
#!/bin/sh
GITDESC=$(git describe --dirty 2>/dev/null | sed -e 's/nbd-//')
if [ -z "$GITDESC" ]; then
  if [ -f "$(dirname "$0")/VERSION" ]; then
    GITDESC=$(cat "$(dirname "$0")/VERSION")
  else
    GITDESC="0.unknown"
  fi
fi
echo $GITDESC
EOF
    chmod +x support/genver.sh
  '';

  # Force HAVE_LINUX_VM_SOCKETS_H to be defined since the header exists but configure doesn't find it
  postConfigure = ''
    echo "=== Forcing HAVE_LINUX_VM_SOCKETS_H definition ==="
    sed -i 's|/\* #undef HAVE_LINUX_VM_SOCKETS_H \*/|#define HAVE_LINUX_VM_SOCKETS_H 1|g' config.h
    grep HAVE_LINUX_VM_SOCKETS_H config.h
  '';

  configureFlags = [
    "--enable-syslog"
    "--with-gnutls"
    "--with-libnl"
    "--disable-manpages"
  ];

  enableParallelBuilding = true;

  meta = with pkgs.lib; {
    description = "Network Block Device - client and server";
    longDescription = ''
      NBD is a Linux kernel module and userland utilities for accessing
      block devices over a network. This package contains the server
      and client utilities.
    '';
    homepage = "https://nbd.sourceforge.net/";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
    maintainers = [];
  };
}
