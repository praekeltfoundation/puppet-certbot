# == Class: certbot::config
#
class certbot::config {
  assert_private()

  file { [
    $certbot::config_dir,
    $certbot::working_dir,
    $certbot::webroot_dir,
    $certbot::log_dir,
  ]:
    ensure => directory,
    owner  => $certbot::user,
    group  => $certbot::group,
    mode   => '0755',
  }

  file { "${certbot::config_dir}/cli.ini":
    ensure => file,
    owner  => $certbot::user,
    group  => $certbot::group,
    mode   => '0644',
  }

  $_base_config = {
    'email'        => $certbot::email,
    'config-dir'   => $certbot::config_dir,
    'work-dir'     => $certbot::working_dir,
    'webroot-path' => $certbot::webroot_dir,
    'logs-dir'     => $certbot::log_dir,
  }

  $_config = merge($certbot::default_config, $certbot::config, $_base_config)
  $_config.each |$setting, $value| {
    ini_setting { "${certbot::config_dir}/cli.ini ${setting} ${value}":
      ensure  => present,
      path    => "${certbot::config_dir}/cli.ini",
      section => '',
      setting => $setting,
      value   => $value,
    }
  }
}
