{ config
, pkgs
, ...
}:
{
  programs.msmtp = {
    enable = true;
    accounts.default = {
      auth = "on";
      tls = "on";
      host = "mail.infomaniak.com";
      from = "monitoring@766c70.com";
      user = "monitoring@766c70.com";
      passwordeval = "cat ${config.age.secrets.mail_infomaniak.path}";
    };
  };
}
