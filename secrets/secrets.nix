let
  user1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPQ5fvwLItahdBiHWbQOm7J97PzlZ5QweNk3/m0Weu+ root@maison";
  user2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID8tl4ACfbuY+gY33fBKAu/V9UbXZVXIYSdHDNRLOjQv";
  user3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMeZmfJWJaN1lgBWOvD2l/pOQLpNvTflIotJnGeyND+d vlp@maison";
in
{
  "nextcloud.age".publicKeys = [ user1 ];
  "prom.age".publicKeys = [ user1 ];
  "mail_infomaniak.age".publicKeys = [ user1 user2 user3];
  "luks_sdb1.age".publicKeys = [ user1 ];
  "luks_sda1.age".publicKeys = [ user1 ];
}

