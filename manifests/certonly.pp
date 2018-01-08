# == Define: certbot::certonly
#
# Certbot certonly command and cron job. Similar to the certonly module in
# puppet-letsencrypt but more limited and simplified.
#
# === Parameters:
#
# [*domains*]
#   List of domains that the issued certificate is for.
#
# [*plugin*]
#   The Certbot certonly plugin to use. Either 'standalone' or 'webroot'.
#
# [*standalone_chall*]
#   The challenge method to use for the standalone plugin. Either 'http' or
#   'tls-sni'. Port 80 or 443 needs to be usable for each, respectively
#   (generally, certbot will need to run as root for that to work).
#
# [*webroot_path*]
#   The path to the directory to use for the webroot plugin. Currently only a
#   single webroot directory is supported. If unset, defaults to the webroot
#   path in the config file, which is generally $certbot::webroot_dir.
#
# [*manage_cron*]
#   Whether or not to manage a cron job for renewals.
#
# [*cron_success_cmd*]
#   Command to run after the cron job succeeds.
define certbot::certonly (
  Array[String, 1]
          $domains,
  Enum['standalone', 'webroot']
          $plugin           = 'webroot',
  Enum['http', 'tls-sni']
          $standalone_chall = 'http',
  Optional[Stdlib::Absolutepath]
          $webroot_path     = undef,
  Boolean $manage_cron      = true,
  String  $cron_success_cmd = '/bin/true'
) {
  include certbot

  $_certonly_cmd = "${certbot::certbot_bin} --noninteractive --agree-tos certonly"
  if $plugin == 'standalone' {
    $_plugin_cmd = "--standalone --preferred-challenges ${standalone_chall}"
  } elsif $plugin == 'webroot' {
    $_plugin_cmd = $webroot_path ? {
      undef   => '--webroot',
      default => "--webroot --webroot-path ${webroot_path}",
    }
  }
  $_domains_cmd = join(prefix($domains, '-d '), ' ')

  $_command = join([$_certonly_cmd, $_plugin_cmd, $_domains_cmd], ' ')

  $_first_domain = $domains[0]
  $_live_path = "${certbot::config_dir}/live/${_first_domain}"

  exec { "certbot certonly ${name}":
    command => $_command,
    path    => ["${certbot::install_dir}/bin"],
    user    => $certbot::user,
    creates => "${_live_path}/cert.pem",
  }

  if $manage_cron {
    cron { "certbot certonly renew ${name}":
      # Run the command as the certbot user and if it succeeds, run the success command as root
      command => "/bin/su ${certbot::user} -s /bin/sh -c '${_command}' && (${cron_success_cmd})",
      user    => 'root',
      hour    => fqdn_rand(24, $name),
      minute  => fqdn_rand(60, $name),
    }
  }
}
