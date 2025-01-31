let
  user1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPQ5fvwLItahdBiHWbQOm7J97PzlZ5QweNk3/m0Weu+ root@maison";
  user2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB1LExkVcGodZAC0w6ma05Kypeuoy5MpTVm/A8RXGp0Q vlp@maison";
in
{
  "nextcloud.age".publicKeys = [ user1 user2 ];
  "prom.age".publicKeys = [ user1 user2 ];
  "mail.age".publicKeys = [ user1 user2 ];
}

