{ config
, pkgs
, ...
}:
{
  # Package definition
  environment.systemPackages = with pkgs; [

    # basic tools
    vim
    neovim
    git
    nnn
    zip
    xz
    unzip
    p7zip
    ripgrep
    jq
    yq-go
    eza
    fzf
    incus

    # networking tools
    openvpn
    lynx
    mtr
    iperf3
    dnsutils
    ldns
    aria2
    socat
    nmap
    ipcalc
    curl
    wget

    # misc
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg
    pass

    # productivity
    glow

    # monitoring
    btop
    iotop
    iftop

    # system call monitoring
    strace
    ltrace
    lsof

    # system tools
    sysstat
    lm_sensors
    ethtool
    pciutils
    usbutils
    nfs-utils
    go
    epsonscan2
    ncdu
    speedtest-go

    # NC dependencies
    exiftool
    ffmpeg
    imagemagick
    nodejs
    perl

    # apps
    caddy
    ttyd
    minidlna
  ];
}
