{
  config,
  pkgs,
  ...
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
    accounts.thomas = {
      host = "smtp.fdn.fr";
      from = "thomas@criscione.fr";
      user = "thomas@criscione.fr";
      passwordeval = "$(cat ${config.age.secrets.mail_perso.path})";
    };
  };
};
