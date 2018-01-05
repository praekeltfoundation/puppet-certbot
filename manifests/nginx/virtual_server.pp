# == Define: certbot::nginx::virtual_server
#
# Set up an ACME-issued and renewed certificate (Let's Encrypt) with certbot
# and Nginx.
#
# Step 1: Set up your Nginx stuff, without SSL, preferably using a virtual
#         server resource (see note).
# Step 2: Add the certbot class to the node, together with a
#         certbot::nginx::virtual_server resource for each
#         nginx::resource::server.
# Step 3: Do a Puppet run. Check that certbot fetched your certificates.
# Step 4: Set *enable_certs* to true.
# Step 5: Do a Puppet run. Check that Nginx's HTTPS works.
#
# NOTE: Making a virtual server resource usually just involves adding an '@' to
# the resource, e.g.: @nginx::resource::server { 'example.com': ... }
# In order for this to auto-magically set the SSL parameters on your Nginx
# server resource, the server must be declared as a virtual resource and
# *realize_server* must be true. Otherwise, you must set the *ssl*, *ssl_cert*,
# *ssl_key*, and other SSL parameters manually and the *enable_certs* parameter
# doesn't do much.
#
# == Parameters:
#
# [*server*]
#   The name of the Nginx::Resource::Server resource to use. Defaults to this
#   resource's name.
#
# [*domains*]
#   The list of domains to fetch a certificate for. A single certificate will be
#   fetched. If unset, the *server_name* parameter for the Nginx server resource
#   will be used as the list of domains.
#
# [*location_params*]
#   A hash of any extra parameters to add to the Nginx location resource created
#   to serve ACME challenge requests.
#
# [*enable_certs*]
#   Whether or not to use the generated certificates for Nginx. This should only
#   be switched on after the initial certificate is issued. If this is used,
#   you should not set the *ssl*, *ssl_cert*, or *ssl_key* parameters on the
#   virtual server resource (this is done by this resource rather).
#
# [*enable_redirect*]
#   Takes effect when *enable_certs* is true. Whether or not to enable the HTTP
#   to HTTPS redirect for the Nginx server resource. If this is used, you should
#   not set the *ssl_redirect* parameter on the virtual server resource.
#
# [*enable_stapling*]
#   Takes effect when *enable_certs* is true. Whether or not to enable the OCSP
#   stapling for the Nginx server resource. If this is used, you should not set
#   the *ssl_stapling*, *ssl_stapling_verify*, or *ssl_trusted_cert* parameters
#   on the virtual server resource.
#
# [*manage_cron*]
#   Whether or not to set up a cron job to renew the certificate.
#
# [*nginx_reload_cmd*]
#   A command to run to reload Nginx after the cron job command succeeds.
define certbot::nginx::virtual_server (
  String  $server           = $name,
  Optional[Array[String, 1]]
          $domains          = undef,
  Hash    $location_params  = {},
  Optional[Boolean]
          $enable_certs     = undef,
  Boolean $enable_redirect  = true,
  Boolean $enable_stapling  = true,
  Boolean $manage_cron      = true,
  String  $nginx_reload_cmd = '/usr/sbin/nginx -s reload',
) {
  # Either fetch certificates for the domains passed as a parameter, or try to
  # detect the domains from the server resource's 'server_name' parameter.
  if $domains {
    $_domains = $domains
  } else {
    $_domains = getparam(Nginx::Resource::Server[$server], 'server_name')
    if ! $_domains {
      fail("Unable to find Nginx server resource '${server}' and no domains specified.")
    }
  }

  certbot::nginx::webroot { $name:
    domains         => $_domains,
    server          => $server,
    manage_cron     => $manage_cron,
    location_ssl    => $enable_certs,
    location_params => $location_params,
  }

  $_first_domain = $_domains[0]
  $_live_path = "${certbot::config_dir}/live/${_first_domain}"

  if $enable_certs == undef {
    if $certbot::config_dir == '/etc/letsencrypt' {
      $_enable_certs = member($::certbot_live_certs, $_first_domain)
    } else {
      $_warning = @("END"/L)
Certificate presence can only be detected with the default config directory,
\$certbot::config_dir='/etc/letsencrypt', not '${certbot::config_dir}'. You must
adjust the \$enable_certs parameter manually to enable use of the certificates.
| END
      warning($_warning)
      $_enable_certs = false
    }
  } else {
    $_enable_certs = $enable_certs
  }

  if $_enable_certs {
    $_cert_params = {
      ssl      => true,
      ssl_cert => "${_live_path}/fullchain.pem",
      ssl_key  => "${_live_path}/privkey.pem",
    }
    $_redirect_params = $enable_redirect ? {
      true  => {
        ssl_redirect => true,
      },
      false => {},
    }
    $_stapling_params = $enable_stapling ? {
      true => {
        ssl_stapling        => true,
        ssl_stapling_verify => true,
        ssl_trusted_cert    => "${_live_path}/chain.pem",
      },
      false => {},
    }

    $ssl_params = merge($_cert_params, $_redirect_params, $_stapling_params)
  } else {
    $ssl_params = {}
  }

  # Add the SSL parameters to the server resource using a collector and, in
  # doing so, realize the virtual resource.
  # https://docs.puppet.com/puppet/4.9/lang_virtual.html
  Nginx::Resource::Server <| title == $server |> { * => $ssl_params }
}
