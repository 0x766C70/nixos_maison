{ config
, pkgs
, ...
}:
{
  services.ttyd = {
    enable = true;
    writeable = true;
  };
}
