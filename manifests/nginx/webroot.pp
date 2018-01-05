# == Define: certbot::nginx::webroot
#
# == Parameters:
#
# [*domains*]
#   The list of domains to fetch a certificate for. A single certificate will be
#   fetched.
#
# [*server*]
#   The name of the Nginx::Resource::Server resource to use. Defaults to this
#   resource's name.
#
# [*manage_cron*]
#   Whether or not to set up a cron job to renew the certificate.
#
# [*nginx_reload_cmd*]
#   A command to run to reload Nginx after the cron job command succeeds.
#
# [*location_ssl*]
#   Value for the 'ssl' parameter for the Nginx::Resource::Location resource.
#   For some versions of the Nginx module it is necessary that this value
#   matches the 'ssl' parameter of the server resource.
#
# [*location_params*]
#   A hash of any extra parameters to add to the Nginx location resource created
#   to serve ACME challenge requests.
define certbot::nginx::webroot (
  Array[String] $domains,
  String        $server           = $name,
  Boolean       $manage_cron      = true,
  String        $nginx_reload_cmd = '/usr/sbin/nginx -s reload',
  Boolean       $location_ssl     = false,
  Hash          $location_params  = {},
) {
  nginx::resource::location { "acme-challenge-${server}":
    server      => $server,
    location    => '/.well-known/acme-challenge/',
    www_root    => $certbot::webroot_dir,
    index_files => [],
    autoindex   => 'off',
    ssl         => $location_ssl,
    *           => $location_params,
  }
  -> certbot::certonly { "nginx-${server}":
    domains          => $domains,
    plugin           => 'webroot',
    manage_cron      => $manage_cron,
    cron_success_cmd => $nginx_reload_cmd,
  }
}
