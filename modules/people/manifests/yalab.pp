# -*- coding: utf-8 -*-
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
    ['cmigemo', 'fontforge']:
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

  file { "${home}/.gitignore":
    ensure  => 'link',
    target  => "${dotfiles}/.gitignore",
    require => Repository[$dotfiles]
  }

  download { "Inconsolata.otf":
    path   => "${home}/Downloads/Inconsolata.otf",
    source => "http://levien.com/type/myfonts/Inconsolata.otf"
  }

  download { "migu-1m-20130617.zip":
    path   => "${home}/Downloads/migu-1m-20130617.zip",
    source => "http://sourceforge.jp/frs/redir.php?m=iij&f=%2Fmix-mplus-ipa%2F59022%2Fmigu-1m-20130617.zip"
  }

  exec { "unzip mig-1m":
    cwd     => "${home}/Downloads",
    user    => "${::boxen_user}",
    command => "unzip http://sourceforge.jp/frs/redir.php?m=iij&f=%2Fmix-mplus-ipa%2F59022%2Fmigu-1m-20130617.zip",
    require => Download["migu-1m-20130617.zip"],
    unless => ["test -f /Library/Fonts/Ricty-Regular.ttf"]
  }

  download { "ricty_generator.sh":
    path   => "${home}/Downloads/ricty_generator.sh",
    source => "https://raw.github.com/yascentur/Ricty/3.2.2/ricty_generator.sh"
  }

  exec { "Generate Ricty font":
    cwd     => "${home}/Downloads",
    user    => "${::boxen_user}",
    command => "sh ricty_generator.sh Inconsolata.otf migu-1m-20130617-2/migu-1m-regular.ttf migu-1m-20130617-2/migu-1m-bold.ttf",
    require => [Package['fontforge'], Exec["unzip mig-1m"]],
    unless => ["test -f /Library/Fonts/Ricty-Regular.ttf"]
  }

  file {"/Library/Fonts/Ricty-Bold.ttf":
    source => "${home}/Downloads/Ricty-Bold.ttf",
    require => Exec["Generate Ricty font"]
  }

  file {"/Library/Fonts/Ricty-Regular.ttf":
    source => "${home}/Downloads/Ricty-Regular.ttf",
    require => Exec["Generate Ricty font"]
  }
  nodejs::module {"generator-angular": node_version => 'v0.10' }
}
