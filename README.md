# puppet-certbot

[![Build Status](https://img.shields.io/travis/praekeltfoundation/puppet-certbot.svg?style=flat-square)](https://travis-ci.org/praekeltfoundation/puppet-certbot)
[![Puppet
Forge](http://img.shields.io/puppetforge/v/praekeltfoundation/certbot.svg?style=flat-square)](https://forge.puppetlabs.com/praekeltfoundation/certbot)

Puppet module to manage the [EFF](https://www.eff.org/)'s client for [Let's Encrypt](https://letsencrypt.org/), [Certbot](https://certbot.eff.org/)

## Why?
There are a few Puppet modules out there for Certbot/Let's Encrypt. Why have we written our own one? Other than a lack of maintenance on some of the existing modules, ours differs in that:
* It installs Certbot from PyPI using `pip` in a virtualenv so that you can install the latest version
* It runs Certbot as a non-root user with limited privileges by default
* It automates all of the steps around enabling HTTPS for an Nginx server with Let's Encrypt certificates

## Warning
We don't recommend you use this in production just yet for the following reasons:
* There are no real tests yet
* We've only used this on Debian 8 (Jessie)
* We've only used this for webroot-based (`http-01`) challenges with Nginx and standalone challenges
* We use some hacky Puppet features (virtual resources) to "auto-magically" set up SSL settings for Nginx servers
* The code is likely to change substantially

## Usage
Set up the basics:
```puppet
class { 'certbot':
  email => 'letsencrypt@example.com',
}
```

Set up an Nginx server and `certbot::nginx::virtual_server` resource:
```puppet
@nginx::resource::server { 'myserver':
  server_name => ['foo.example.com'],
  proxy       => 'http://localhost:5000/',
}

certbot::nginx::virtual_server { 'myserver': }
```

After one Puppet run the certificates should be issued. Run Puppet once more for the certificates to be used.

Note that by default this module will try to install the package 'python-virtualenv'. If this is not desired, pass `manage_python => false`.
