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
#
# [*nginx_virtual_servers*]
#   Hash of certbot::nginx::virtual_server resources to create.
class certbot (
  String               $email,

  Optional[String]     $version       = undef,
  Boolean              $manage_python = false,

  String               $user        = 'certbot',
  String               $group       = 'certbot',
  Boolean              $manage_user = true,

  # These paths are still a hangover from when certbot was called 'letsencrypt'
  Stdlib::Absolutepath $install_dir = '/opt/letsencrypt',
  Stdlib::Absolutepath $working_dir = '/var/lib/letsencrypt',
  Stdlib::Absolutepath $config_dir  = '/etc/letsencrypt',
  Stdlib::Absolutepath $log_dir     = '/var/log/letsencrypt',

  Hash[String, String] $config         = {},
  Hash[String, String] $default_config = {
    'server'              => 'https://acme-v01.api.letsencrypt.org/directory',
    'no-eff-email'        => 'False',
    'expand'              => 'True',
    'keep-until-expiring' => 'True',
  },

  Hash                 $nginx_virtual_servers = {},
) {
  # Path to the certbot configuration file. To be used by other classes via
  # $certbot::config_file.
  $config_file = "${config_dir}/cli.ini"

  # Path to a directory that can be used for webroot-based challenge responses.
  # To be used by other classes via $certbot::webroot_dir.
  $webroot_dir = "${working_dir}/webroot"

  # Path to the certbot binary in the virtualenv. To be used by other classes
  # via $certbot::certbot_bin.
  $certbot_bin = "${install_dir}/bin/certbot"

  contain certbot::user
  contain certbot::install
  contain certbot::config

  create_resources(certbot::nginx::virtual_server, $nginx_virtual_servers)
}
