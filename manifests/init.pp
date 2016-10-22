class fusiondirectory(
    $ldap_host,
    $ldap_base,
    $ldap_admin_dn,
    $ldap_admin_pass,
  ){
  package { 'fusiondirectory':
    ensure => present,
  }

  package { 'fusiondirectory-plugin-systems':
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
  }
}
