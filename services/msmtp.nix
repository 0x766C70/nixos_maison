{ config
, pkgs
, ...
}:
{
  programs.msmtp = {
    enable = true;
    defaults = {
      port = 587;
      auth = "plain";
      tls = "on";
      tls_starttls = "on";
    };
    accounts.default = {
      host = "mail.infomaniak.com";
      from = "monitoring@766c70.com";
      user = "monitoring@766c70.com";
      passwordeval = "$(cat ${config.age.secrets.mail_infomaniak.path})";
    };
  };
}
