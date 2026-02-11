{
  config,
  pkgs,
  ...
}:
{
  # OpenVPN configuration for FDN
  services.openvpn.servers = {
    officeVPN = {
      # Main OpenVPN configuration
      # Replace the content below with your actual fdn.conf settings
      config = ''
        client
        dev tun
        proto udp
        remote YOUR_VPN_SERVER_HERE 1194
        resolv-retry infinite
        nobind
        persist-key
        persist-tun
        
        # TLS/SSL options
        ca /path/to/ca.crt
        cert /path/to/client.crt
        key /path/to/client.key
        
        # Authentication with password from agenix
        auth-user-pass ${config.age.secrets.openvpn.path}
        
        # Cipher and compression
        cipher AES-256-CBC
        comp-lzo
        
        # Logging
        verb 3
      '';
      
      # Ensure service starts after network is up
      updateResolvConf = true;
    };
  };
}
