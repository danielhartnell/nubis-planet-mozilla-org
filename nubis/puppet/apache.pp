# Define how Apache should be installed and configured
# We should try to recycle the puppetlabs-apache puppet module in the future:
# https://github.com/puppetlabs/puppetlabs-apache
#

include nubis_discovery

nubis::discovery::service {
  $project_name:
    tags     => [ 'apache' ],
    port     => 80,
    check    => '/usr/bin/curl -If http://localhost:80',
    interval => '30s',
}

class {
    'apache':
        mpm_module          => 'event',
        default_mods        => true,
        default_vhost       => false,
        default_confd_files => false,
        service_enable      => true,
        service_ensure      => true;
    'apache::mod::status':;
    'apache::mod::remoteip':
        proxy_ips => [ '127.0.0.1', '10.0.0.0/8' ];
}

apache::vhost { 'planet':
    port              => 80,
    default_vhost     => true,
    docroot           => '/var/www/html',
    directoryindex    => '/var/www/html/index.html',
    docroot_owner     => 'root',
    docroot_group     => 'root',
    block             => ['scm'],
    setenvif          => 'X_FORWARDED_PROTO https HTTPS=on',
    access_log_format => '%a %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"',
    custom_fragment   => 'FileETag None',
    headers           => [
      "set X-Nubis-Version ${project_version}",
      "set X-Nubis-Project ${project_name}",
      "set X-Nubis-Build   ${packer_build_name}",
    ],
    rewrites          => [
      {
        comment      => 'HTTPS redirect',
        rewrite_cond => ['%{HTTP:X-Forwarded-Proto} =http'],
        rewrite_rule => ['. https://%{HTTP:Host}%{REQUEST_URI} [L,R=permanent]'],
      }
    ]
}

