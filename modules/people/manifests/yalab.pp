class emacs {
  include homebrew

  $version = '24.3-boxen1'

  homebrew::formula { 'emacs':
    before => Package['boxen/brews/emacs'] ;
  }

  package { 'boxen/brews/emacs':
    ensure          => $version,
    install_options => ['--cocoa'],
  }

  $target = "${homebrew::config::installdir}/Cellar/emacs/${version}/Emacs.app"

  file { '/Applications/Emacs.app':
    ensure  => link,
    target  => $target,
    require => Package['boxen/brews/emacs']
  }
}

class people::yalab {
  include autoconf
  include emacs
  include firefox
  include chrome
  include dropbox
  include skype

  $home = "/Users/${::boxen_user}"
  $project_dir = "${home}/project"
  $dotfiles   = "${project_dir}/dotfiles"


  package {
    ['cmigemo']:
  }

  file { $project_dir: 
    ensure => directory
  }

  repository { $dotfiles:
    source   => 'yalab/dotfiles',
    require  => File[$project_dir]
  }

  file { "${home}/.zshrc":
    ensure  => 'link',
    target  => "${dotfiles}/.zshrc",
    require => Repository[$dotfiles]
  }

  file { "${home}/.emacs.d":
    ensure  => 'link',
    target  => "${dotfiles}/.emacs.d",
    require => Repository[$dotfiles]
  }

  file { "${home}/.gitconfig":
    ensure  => 'link',
    target  => "${dotfiles}/.gitconfig",
    require => Repository[$dotfiles]
  }
}
