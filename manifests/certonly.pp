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
# [*preferred_challenges*]
#   An ordered list of challenge methods to use. Currently only used for the
#   standalone plugin
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
  Array[String, 1]               $domains,
  Enum['standalone', 'webroot']  $plugin               = 'webroot',
  Array[String]                  $preferred_challenges = [],
  Optional[Stdlib::Absolutepath] $webroot_path         = undef,
  Boolean                        $manage_cron          = true,
  String                         $cron_success_cmd     = '/bin/true'
) {
  include certbot

  $_certonly_args = [
    $certbot::certbot_bin,
    '--config', $certbot::config_file,
    '--noninteractive', '--agree-tos',
    'certonly'
  ]
  if $plugin == 'standalone' {
    if !empty($preferred_challenges) {
      $_plugin_args = ['--standalone', '--preferred-challenges', join($preferred_challenges, ',')]
    } else {
      $_plugin_args = ['--standalone']
    }
  } elsif $plugin == 'webroot' {
    if $webroot_path {
      $_plugin_args = ['--webroot', '--webroot-path', $webroot_path]
    } else {
      $_plugin_args = ['--webroot']
    }
  }
  $_domains_args = flatten($domains.map |$domain| { ['-d', $domain] })

  $_command = join($_certonly_args + $_plugin_args + $_domains_args, ' ')

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
