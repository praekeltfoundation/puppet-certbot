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
# [*version*]
#   The version of certbot to install.
#
# [*manage_python*]
#   Whether or not to define the 'python' class resource.
#
# [*user*]
#   The user to install and run certbot as. Defaults to 'certbot'. Note that
#   certbot needs to run as root (to bind to port 80 or 443) for the standalone
#   challenges to work.
#
# [*group*]
#   The group to install and run certbot as. Defaults to 'certbot'.
#
# [*manage_user*]
#   Whether to manage the creation of the user and group that certbot runs as.
#   Defaults to true but won't attempt to manage the user or group if they are
#   'root'.
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

  Optional[String]
          $version            = undef,
  Boolean $manage_python      = false,

  String  $user               = 'certbot',
  String  $group              = 'certbot',
  Boolean $manage_user        = true,

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

  if $manage_user {
    if $group != 'root' {
      group { $group:
        ensure => present,
        system => true,
      }
    }
    if $user != 'root' {
      user { $user:
        ensure     => present,
        gid        => $group,
        system     => true,
        managehome => true,
        home       => $working_dir,
        shell      => '/usr/sbin/nologin',
      }
    }
  }

  # Path to a directory that can be used for webroot-based challenge responses.
  # To be used by other classes via $certbot::webroot_dir.
  $webroot_dir = "${working_dir}/webroot"

  file { [
    $working_dir,
    $webroot_dir,
    $log_dir,
    $config_dir,
  ]:
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0755',
  }

  file { "${config_dir}/cli.ini":
    ensure => file,
    owner  => $user,
    group  => $group,
    mode   => '0644',
  }

  contain certbot::install

  # Path to the certbot binary in the virtualenv. To be used by other classes
  # via $certbot::certbot_bin.
  $certbot_bin = "${install_dir}/bin/certbot"

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
