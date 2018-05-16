# == Class: certbot::install
#
# Create the virtualenv and install certbot.
class certbot::install {
  assert_private()

  if $certbot::manage_user {
    if $certbot::group != 'root' {
      group { $certbot::group:
        ensure => present,
        system => true,
      }
    }
    if $certbot::user != 'root' {
      user { $certbot::user:
        ensure     => present,
        gid        => $certbot::group,
        system     => true,
        managehome => true,
        home       => $certbot::working_dir,
        shell      => '/usr/sbin/nologin',
      }
    }
  }

  if $certbot::manage_python {
    package { 'python-virtualenv':
      ensure => installed,
    }
  }

  if $certbot::version {
    $_install_unless = "pip freeze | grep '^certbot==${$certbot::version}$'"
  } else{
    $_install_unless = "python -c 'import certbot'"
  }

  file { $certbot::install_dir:
    ensure => directory,
    owner  => $certbot::user,
    group  => $certbot::group,
    mode   => '0755',
  }
  -> exec { 'create certbot virtualenv':
    command => "virtualenv ${certbot::install_dir}",
    path    => $::path,
    user    => $certbot::user,
    creates => "${certbot::install_dir}/bin/python",
  }
  -> exec { 'update certbot pip':
    command => 'pip install --upgrade pip',
    path    => ["${certbot::install_dir}/bin", $::path],
    user    => $certbot::user,
    # Make sure we have pip >= 9.x
    unless  => "[ $(pip --version | sed -nE 's/^pip ([0-9]+).*/\\1/p') -ge 9 ]"
  }
  -> exec { 'install certbot':
    command => 'pip install certbot',
    path    => ["${certbot::install_dir}/bin", $::path],
    user    => $certbot::user,
    unless  => $_install_unless,
  }
}
