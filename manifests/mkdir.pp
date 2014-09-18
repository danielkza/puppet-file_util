define file_util::mkdir(
    $path  = $title,
    $owner = undef,
    $group = undef,
    $mode  = undef
) {
    validate_absolute_path($path)
    
    $path_parent = regsubst($path, '/[^/]*$', '')
    if $path_parent != "" and !defined(File[$path_parent]) {
        file { $path_parent: 
            ensure => directory,
            owner  => $owner,
            group  => $group,
            mode   => $mode,
        }
        
        util::mkdir { $path_parent:
            owner => $owner,
            group => $group,
            mode  => $mode,
        }
    }
}
