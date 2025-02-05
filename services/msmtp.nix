{
  config,
  pkgs,
  ...
}:
{
  age.secrets.mail = {                                                                                                                                       
    file = ../secrets/mail.age;
  };                                   
  age.secrets.mail_perso = {                                                                                                                                 
    file = ../secrets/mail_perso.age;
  };                

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
}
