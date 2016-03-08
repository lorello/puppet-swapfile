# Class: swapfile
# ===========================
#
# Install and configure dphys-swapfile package to manage swap space on file
# instead of a dedicated disk partition
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#
# * `ensure`
#  present or absent, manage package and config file presence (default: present)
# * `file_path`
#  full path of the file used for memory swap (default: /var/swap)
# * `size`
#  size in Mb of the swap file (default: 2 * memorysize)
#
# Examples
# --------
#
# Create a 4G swapfile on /mnt path, typically used on EC2 hosts, where
# `/mnt` is mounted on ephymeral storage.
#
# @example
#    class { 'swapfile':
#      file_path => '/mnt/swapfile',
#      size      => 4096,
#    }
#
# Authors
# -------
#
# Author Name <lorenzo.salvadorini@softecspa.it>
#
# Copyright
# ---------
#
# Copyright 2016 Lorenzo Salvadorini, unless otherwise noted.
#
class swapfile(
  $ensure    = present,
  $file_path = '/var/swap',
  $size      = undef,
) {

  validate_re($ensure, '(present|absent)', "ensure must be 'present' or 'absent', checked value is '${ensure}'")

  if ! is_absolute_path($file_path) {
    fail("file_path must a valid absolute path, checked value is '${file_path}'")
  }

  case $::osfamily {
    'Debian': {
      case $::lsbdistid {
        'Ubuntu': {
          if $::lsbmajdistrelease < 10 {
            fail('Ubuntu before Precise is not supported (missing package)')
          }
        }
        'Debian': {
          if $::lsbmajdistrelease < 7 {
            fail('Debian before Wheezy is not supported (missing package)')
          }
        }
        default: {
          warn("Your OS distribution is unknown (value: ${::lsbdistid}), be sure the package dphys-swapfile is available in your repositories")
        }
      }
    }
    default: {
      fail("This module is not supported on OS family '${::osfamily}'")
    }
  }

  if $size == undef {
    $real_size = 2 * $::memorysize_mb
  } else {
    if is_integer($size) {
      $real_size = $size
    } else {
      fail("Invalid size: it should be undef or an integer value,\
      current value is '${size}'")
    }
  }

  file { '/etc/dphys-swapfile':
    ensure  => $ensure,
    content => "#File managed by Puppet, don't edit manually\nCONF_SWAPFILE=${file_path}\nCONF_SWAPSIZE=${real_size}\n",
  }

  package { 'dphys-swapfile':
    ensure => $ensure,
  }

  if $ensure == present {
    service { 'dphys-swapfile':
      ensure => running,
      enable => true,
    }
  }
}
