require boxen::environment
require homebrew
require gcc

Exec {
  group       => 'staff',
  logoutput   => on_failure,
  user        => $boxen_user,

  path => [
    "${boxen::config::home}/rbenv/shims",
    "${boxen::config::home}/rbenv/bin",
    "${boxen::config::home}/rbenv/plugins/ruby-build/bin",
    "${boxen::config::home}/homebrew/bin",
    '/usr/bin',
    '/bin',
    '/usr/sbin',
    '/sbin'
  ],

  environment => [
    "HOMEBREW_CACHE=${homebrew::config::cachedir}",
    "HOME=/Users/${::boxen_user}"
  ]
}

File {
  group => 'staff',
  owner => $boxen_user
}

Package {
  provider => homebrew,
  require  => Class['homebrew']
}

Repository {
  provider => git,
  extra    => [
    '--recurse-submodules'
  ],
  require  => File["${boxen::config::bindir}/boxen-git-credential"],
  config   => {
    'credential.helper' => "${boxen::config::bindir}/boxen-git-credential"
  }
}

Service {
  provider => ghlaunchd
}

Homebrew::Formula <| |> -> Package <| |>

define download ($source, $path = $name, $timeout = 300) {
  exec {
    "download $source":
    command => "curl -s -o $path $source",
    creates => $path,
    timeout => $timeout,
    unless  => ["test -f $path"]
  }
}

node default {
  class { 'memcached':
      port => 11211,
      host => "localhost"
  }

  # core modules, needed for most things
  include dnsmasq
  include git
  include hub
  include nginx
  include mysql
  include postgresql
  include memcached
  include virtualbox
  include vagrant
  include hipchat

  # node versions
  include nodejs::v0_10
  class { 'nodejs::global': }
  nodejs::module {"bower":         node_version => 'v0.10' }
  nodejs::module {"yo":            node_version => 'v0.10' }
  nodejs::module {"grunt-cli":     node_version => 'v0.10' }
  nodejs::module {"grunt-docular": node_version => 'v0.10' }

  # default ruby versions
  include ruby
  class { 'ruby::global': version => '2.0.0-p353' }
  ruby::version { '2.1.0': }

  include python
  python::pip {"PyYAML": virtualenv => "${python::config::global_venv}"}

  # common, useful packages
  package {
    [
      'ack',
      'findutils',
      'gnu-tar',
      'git-crypt',
      'phantomjs',
      'doxygen',
      'imagemagick',
      'qt',
      'pcre'
    ]:
  }

  file { "${boxen::config::srcdir}/our-boxen":
    ensure => link,
    target => $boxen::config::repodir
  }


  File <| title == $mysql::config::configfile |> {
    content => template("${boxen::config::repodir}/templates/my.cnf.erb"),
    notify => Service['dev.mysql'],
  }

  mysql::user::grant{$boxen_user:
    database => "*",
    username => $boxen_user
  }

  include vagrant
  exec {"Add precise64 vagrant box":
      user    => $boxen_user,
      command => "vagrant box add precise64 http://files.vagrantup.com/precise64.box",
      timeout => 1200,
      unless => "vagrant box list | grep precise64 2>/dev/null"
  }

  exec {
    'pip install awscli':
    cwd    => '/tmp',
    path   => [ '/bin','/usr/bin','/opt/boxen/homebrew/bin' ],
    unless => ['which aws 2>/dev/null']
  }
}
