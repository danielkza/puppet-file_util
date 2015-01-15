# This resource manages a file, usually a configuration file, by automatically
# selecting sources according to pre-defined rules:
#
# 1) Sources live on the caller file module's files folder.
# 2) Sources have the form <sources_path>/<file_path>[-selector]
# 3) Selectors, in order of use, from first to last:
#  - $::fqdn
#  - $::hostname
#  - host_groups, in order.
#  - '' (the separator is ommited), a.k.a. the original file name
# 4) If none of the previous sources are available, paths listed in the
#  'extra_sources' param, if any, will be used (in passed order).
#
# All the other parameters are equivalent to their 'file' counterparts,
# but with sane defaults allowing them to be ommited for configuration files.
# The only special case is 'content', which disables the source lookup logic.
#
# Parameters:
# 
# path  - Destination path
# ensure  - See puppet's file type
# content - Same as above
# source  - Source path. If not specified, a path equal to the destination path
#       but relative to the caller module's folder, possibly inside the 
#       source_prefix, will be used
# source_prefix - When leaving source unspecified, selects a folder to prefix
#         before the destination path, inside the module folder. So
#         for a destination of '/etc/krb5.conf' and prefix of 'kerberos',
#         the file will be searched in ${module_folder}/kerberos/etc/krb5.conf
# replace, owner, group, mode, recurse - See puppet's file type
# extra_sources - Add's secondary fallback sources if the primary ones are not found.
#         These are *absolute* URLs.
# host_groups   - List of group names to be used 

define file_util::cfg(
  $path          = $title,
  $ensure        = file,
  $content       = '$undef$',
  $template_mode = undef,
  $source        = undef,
  $source_prefix = undef,
  $host_sep      = '@',
  $group_sep     = '#', 
  $extra_sources = undef,
  $host_groups   = undef,
  $replace       = undef,
  $owner         = 'root',
  $group         = 'root',
  $mode          = '0644',
  $recurse       = undef,
  $recurselimit  = undef,
  $sourceselect  = undef,
  $purge         = undef,
  $links         = undef,
  $force         = undef
) { 

  File {
    ensure       => $ensure,
    path         => $path,
    replace      => $replace,
    owner        => $owner,
    group        => $group,
    mode         => $mode,
    recurse      => $recurse,
    recurselimit => $recurselimit,
    sourceselect => $sourceselect,
    purge        => $purge,
    links        => $links,
    force        => $force
  }

  if $ensure == 'absent' {
    file { $title:
      ensure => absent,
      path   => $path
    }
  } else {
    # Work around the fact that even passing content as undef sometimes
    # causes the 'You cannot specify more than one of content, source, target'
    # error.
    # For some stupid reason, undef == '', work around it as well.

    if $content != '$undef$' {
      if $source != undef {
        fail("You must specify one of: content, source")
      }

      file { $title: 
        content => $content
      }
    } else {  
      if empty($source) {
        if $source_prefix {
          $source_path = "${source_prefix}/${path}"
        } else {
          $source_path = $path
        }
      } else {
        $source_path = $source
      }

      if $trusted[certname] {
        $trusted_hostname_split = split($trusted[certname], '[.]')
        $trusted_hostname = $trusted_hostname_split[0]
        $host_sources = prefix(
          [$trusted[certname], $trusted_hostname], "${source_path}${host_sep}")
      } else {
        $host_sources = []
      }

      $group_sources = prefix($host_groups, "${source_path}${group_sep}")  
      $base_sources = ($host_sources + $group_sources) << $source_path
      
      if empty($extra_sources) {
        $sources = $base_sources
      } else {
        $sources = $base_sources + any2array($extra_sources)
      }

      if $template != undef {
        $combine = $template_mode ? {
          'single'  => false,
          'combine' => true,
          default   => fail("Invalid cfg template mode ${template_mode}")
        }

        $template_sources = filter($sources) |$source| {
          file_exists($source)
        }
      }

      file { $title:
        source => $sources
      }
    }
  }
}
