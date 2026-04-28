let
  user1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPQ5fvwLItahdBiHWbQOm7J97PzlZ5QweNk3/m0Weu+ root@maison";
in
{
  "nextcloud.age".publicKeys = [ user1 ];
  "prom.age".publicKeys = [ user1 ];
  "mail_infomaniak.age".publicKeys = [ user1 ];
  "luks_sdb1.age".publicKeys = [ user1 ];
  "luks_sda1.age".publicKeys = [ user1 ];
}

