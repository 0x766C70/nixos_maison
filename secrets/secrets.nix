let
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPQ5fvwLItahdBiHWbQOm7J97PzlZ5QweNk3/m0Weu+ root@maison";
in
{
  "secret.age".publicKeys = [ user ];
  "nextcloud.age".publicKeys = [ user ];
  "prom.age".publicKeys = [ user ];
  "mail.age".publicKeys = [ user ];
}

