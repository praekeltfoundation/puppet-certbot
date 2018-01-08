# == Class: certbot::user
#
class certbot::user {
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
}
