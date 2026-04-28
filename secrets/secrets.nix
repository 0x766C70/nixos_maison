let
  user1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPQ5fvwLItahdBiHWbQOm7J97PzlZ5QweNk3/m0Weu+ root@maison";
  user2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB1LExkVcGodZAC0w6ma05Kypeuoy5MpTVm/A8RXGp0Q vlp@maison";
  user3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMeZmfJWJaN1lgBWOvD2l/pOQLpNvTflIotJnGeyND+d vlp@maison";
in
{
  "nextcloud.age".publicKeys = [ user1 user2 ];
  "prom.age".publicKeys = [ user1 user2 ];
  "mail.age".publicKeys = [ user1 user2 ];
  "mail_infomaniak.age".publicKeys = [ user1 user2 user3];
  "caddy_mlc.age".publicKeys = [ user1 ];
  "caddy_vlp.age".publicKeys = [ user1 ];
  "luks_sdb1.age".publicKeys = [ user1 ];
  "luks_sda1.age".publicKeys = [ user1 ];
}

