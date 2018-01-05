# == Class: certbot
#
# Install the EFF's ACME (Let's Encrypt) client, certbot. This will install the
# certbot client from PyPI using pip in its own virtualenv and give it its own
# user to run as.
#
# == Parameters:
#
# [*email*]
#   The email address to register with the ACME authority.
#
# [*pip_ensure*]
#   The ensure value for the Python::Pip resource. The version can be set here.
#
# [*manage_python*]
#   Whether or not to define the 'python' class resource.
#
# [*install_dir*]
#   The directory to install to. A virtualenv will be created inside this
#   directory.
#
# [*working_dir*]
#   The working directory for certbot.
#
# [*config_dir*]
#   The config directory for certbot. A file called 'cli.ini' will be created
#   here to store config.
#
# [*log_dir*]
#   The directory to store certbot log files.
#
# [*config*]
#   Any extra configuration to set in certbot's configuration file. Will
#   override *default_config*.
#
# [*default_config*]
#   The base config settings.
class certbot (
  String  $email,

  String  $pip_ensure         = 'present',
  Boolean $manage_python      = false,

  # These paths are still a hangover from when certbot was called 'letsencrypt'
  String  $install_dir        = '/opt/letsencrypt',
  String  $working_dir        = '/var/lib/letsencrypt',
  String  $config_dir         = '/etc/letsencrypt',
  String  $log_dir            = '/var/log/letsencrypt',

  Hash[String, String]
          $config             = {},
  Hash[String, String]
          $default_config     = {
    'server'              => 'https://acme-v01.api.letsencrypt.org/directory',
    'no-eff-email'        => 'False',
    'expand'              => 'True',
    'keep-until-expiring' => 'True',
  },
) {

  group { 'certbot':
    ensure => present,
    system => true,
  }
  user { 'certbot':
    ensure     => present,
    gid        => 'certbot',
    system     => true,
    managehome => true,
    home       => $working_dir,
    shell      => '/usr/sbin/nologin',
  }

  # Path to a directory that can be used for webroot-based challenge responses.
  # To be used by other classes via $certbot::webroot_dir.
  $webroot_dir = "${working_dir}/webroot"

  file {
    default:
      owner => 'certbot',
      group => 'certbot';

    $install_dir:
      ensure => directory,
      mode   => '0755';

    $working_dir:
      ensure => directory,
      mode   => '0755';

    $webroot_dir:
      ensure => directory,
      mode   => '0755';

    $log_dir:
      ensure => directory,
      mode   => '0755';

    $config_dir:
      ensure => directory,
      mode   => '0755';

    "${config_dir}/cli.ini":
      ensure => file,
      mode   => '0644';
  }

  if $manage_python {
    class { 'python': virtualenv => true }
  }

  $virtualenv = "${install_dir}/.venv"
  python::virtualenv { $virtualenv:
    ensure => present,
    owner  => 'certbot',
    group  => 'certbot',
  }

  python::pip { 'certbot':
    ensure     => $pip_ensure,
    virtualenv => $virtualenv,
    owner      => 'certbot',
    group      => 'certbot',
  }

  # Path to the certbot binary in the virtualenv. To be used by other classes
  # via $certbot::certbot_bin.
  $certbot_bin = "${virtualenv}/bin/certbot"

  $_config = merge($default_config, $config, { 'email' => $email })
  $_config.each |$setting, $value| {
    ini_setting { "${config_dir}/cli.ini ${setting} ${value}":
      ensure  => present,
      path    => "${config_dir}/cli.ini",
      section => '',
      setting => $setting,
      value   => $value,
    }
  }
}
