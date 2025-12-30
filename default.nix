{ pkgs ? import <nixpkgs> {} }:

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
  ];

  # Ensure version is set correctly without git
  preConfigure = ''
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
