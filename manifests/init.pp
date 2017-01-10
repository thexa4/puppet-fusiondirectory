class fusiondirectory(
    $ldap_host,
    $ldap_base,
    $ldap_admin_dn,
    $ldap_admin_pass,
    $fusiondirectory_admin_cn = 'administrator',
    $fusiondirectory_admin_pass,
  ){

  if ! defined(Apt::Source['fusiondirectory']) {
    apt::source { 'fusiondirectory':
      comment  => 'Fusiondirectory repository',
      location => 'http://repos.fusiondirectory.org/debian-jessie/',
      key      => {
        'id'     => '5636FC267B643B144F31BCA0E184859262B4981F',
        'server' => 'keys.gnupg.net',
      },
    }
  }

  package { 'fusiondirectory':
    ensure  => present,
    require => Apt::Source['fusiondirectory'],
  }

  package { 'fusiondirectory-plugin-systems':
    ensure  => present,
    require => Package['fusiondirectory'],
  }
  
  package { 'fusiondirectory-plugin-puppet':
    ensure  => present,
    require => Package['fusiondirectory'],
  }

  file { '/etc/fusiondirectory/fusiondirectory.conf':
    group   => 'www-data',
    require => Package['fusiondirectory-plugin-systems'],
    content => epp('fusiondirectory/fusiondirectory.conf', {
      'ldap_host'       => $ldap_host,
      'ldap_base'       => $ldap_base,
      'ldap_admin_dn'   => $ldap_admin_dn,
      'ldap_admin_pass' => $ldap_admin_pass,
    }),
    replace => false,
    mode    => '640',
    notify  => Exec['/usr/sbin/fusiondirectory-setup --yes --check-ldap'],
  }

  ldap::object { "ou=people,${ldap_base}":
    attributes => {
      'ou' => 'people',
      'objectClass' => [
        'organizationalUnit',
      ],
    },
    ensure => present,
    adduser => $ldap_admin_dn,
    addpw => $ldap_admin_pass,
  }

  ldap::object { "uid=${fusiondirectory_admin_cn},ou=people,${ldap_base}":
    attributes => {
      'cn'          => $fusiondirectory_admin_cn,
      'objectClass' => [
        'inetOrgPerson',
        'organizationalPerson',
        'person',
        'top',
      ],
      'userPassword'    => $fusiondirectory_admin_pass,
      'sn'          => 'Administrator',
      'uid'         => $fusiondirectory_admin_cn,
    },
    ensure => present,
    adduser => $ldap_admin_dn,
    addpw => $ldap_admin_pass,
    require => Ldap::Object["ou=people,${ldap_base}"],
  }

  exec { '/usr/sbin/fusiondirectory-setup --yes --check-ldap':
    command     => "/bin/bash -c '/usr/sbin/fusiondirectory-setup --yes --check-ldap <<< ${fusiondirectory_admin_cn}'",
    refreshonly => true,
    require => [File["/etc/fusiondirectory/fusiondirectory.conf"], Ldap::Object["uid=${fusiondirectory_admin_cn},ou=people,${ldap_base}"]],
  }
}
