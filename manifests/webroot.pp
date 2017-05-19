# == Define: certbot::webroot
#
# Certbot certonly command and cron job for the webroot plugin. Makes some
# assumptions about how the webroot is set up-- i.e. there is only one webroot
# directory.
define certbot::webroot (
  Array[String, 1] $domains,
  String $webroot_path = $certbot::webroot_dir,
  Boolean $manage_cron = true,
  String $cron_success_cmd = '/bin/true'
) {
  require certbot

  $_certonly_cmd = "${certbot::certbot_bin} --noninteractive --agree-tos certonly --webroot"
  $_webroot_cmd = "--webroot --webroot-path ${webroot_path}"
  $_domains_cmd = join(prefix($domains, '-d '), ' ')

  $_command = join([$_certonly_cmd, $_webroot_cmd, $_domains_cmd], ' ')

  $_first_domain = $domains[0]
  $_live_path = "${certbot::config_dir}/live/${_first_domain}"

  exec { "certbot certonly ${name}":
    command => $_command,
    path    => ["${certbot::virtualenv}/bin"],
    user    => 'certbot',
    creates => "${_live_path}/cert.pem",
  }

  if $manage_cron {
    cron { "certbot certonly renew ${name}":
      # Run the command as the certbot user and if it succeeds, run the success command as root
      command => "/bin/su certbot -s /bin/sh -c '${_command}' && (${cron_success_cmd})",
      user    => 'root',
      hour    => fqdn_rand(24, $name),
      minute  => fqdn_rand(60, $name),
    }
  }
}
