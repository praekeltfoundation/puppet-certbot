# == Class: certbot::resources
#
# Create certbot defined types. For use with Hiera.
#
# == Parameters:
#
# [*nginx_virtual_servers*]
#   Hash of certbot::nginx_virtual_server resources to create.
class certbot::resources (
  Hash $nginx_virtual_servers = {}
) {
  create_resources(certbot::nginx_virtual_server, $nginx_virtual_servers)
}
