{ config
, pkgs
, ...
}:
{
  programs.msmtp = {
    enable = true;
    accounts.default = {
      host = "smtp.fdn.fr";
      from = "maison@vlp.fdn.fr";
      user = "maison@vlp.fdn.fr";
      passwordeval = "$(cat ${config.age.secrets.mail.path})";
    };
  };
}
