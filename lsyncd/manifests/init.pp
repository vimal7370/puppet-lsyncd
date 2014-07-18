# Lsyncd installation
#
class lsyncd {
        $required_packages = ['gcc', 'gcc-c++', 'make', 'lua-devel', 'tar', 'git', 'wget', 'pkgconfig', 'asciidoc']

        package { $required_packages:
                ensure => present;

                "cmake":
                ensure => absent,
        }

	Exec { logoutput => on_failure, refreshonly => true, }

        exec { "wget_cmake":
                cwd => "/bin",
		refreshonly => false,
                command => "/usr/bin/wget http://www.cmake.org/files/v2.8/cmake-2.8.12.2.tar.gz -O /tmp/cmake-2.8.12.2.tar.gz";

		"tar_zxf_cmake":
                cwd => "/tmp",
		command => "/bin/tar zxf cmake-2.8.12.2.tar.gz",
		subscribe => Exec["wget_cmake"];

        	"config_cmake":
                cwd => "/tmp/cmake-2.8.12.2",
                command => "/tmp/cmake-2.8.12.2/configure",
		subscribe => Exec["tar_zxf_cmake"];

		"gmake_cmake":
                cwd => "/tmp/cmake-2.8.12.2",
		require => Exec["config_cmake"],
		command => "/usr/bin/gmake",
		subscribe => Exec["config_cmake"];

		"makeinstall_cmake":
                cwd => "/tmp/cmake-2.8.12.2",
		command => "/usr/bin/make install",
		subscribe => Exec["gmake_cmake"];

		"cleanup_cmake":
		cwd => "/bin",
		command => '/bin/rm -rf /tmp/cmake-2.8.12.2.tar.gz /tmp/cmake-2.8.12.2',
		subscribe => Exec["makeinstall_cmake"];

                "softlink_cmake":
                cwd => "/bin",
                command => '/bin/rm -f /usr/bin/cmake && /bin/ln -s /usr/local/bin/cmake /usr/bin/',
		refreshonly => false,
		subscribe => Exec["cleanup_cmake"];
        }

	exec { "git_clone_lsyncd":
		cwd => "/bin",
		command => '/bin/rm -rf /tmp/lsyncd && /usr/bin/git clone https://github.com/axkibe/lsyncd.git /tmp/lsyncd',
		subscribe => Exec["softlink_cmake"];

		"cmake_lsyncd":
		cwd => "/tmp/lsyncd",
		command => "/usr/bin/cmake .",
		subscribe => Exec["git_clone_lsyncd"];

		"make_lsyncd":
		cwd => "/tmp/lsyncd",
		command => '/usr/bin/make',
		subscribe => Exec["cmake_lsyncd"];

		"makeinstall_lsyncd":
		cwd => "/tmp/lsyncd",
		command => "/usr/bin/make install",
		subscribe => Exec["make_lsyncd"];

		"cleanup_lsyncd":
		cwd => "/bin",
                command => '/bin/rm -rf /tmp/lsyncd',
                subscribe => Exec["makeinstall_lsyncd"];
	}	

        file { '/etc/init.d/lsyncd':
                ensure => present,
                source => 'puppet:///modules/lsyncd/lsyncd.init',
		subscribe => Exec["makeinstall_lsyncd"],
		owner => root,
		group => root,
		mode => 0755;

                '/etc/lsyncd.conf':
		ensure => present,
                source => 'puppet:///modules/lsyncd/lsyncd.conf',
                subscribe => Exec["makeinstall_lsyncd"],
                owner => root,
                group => root,
                mode => 0644;

        }
	
	exec { "chkconfig_add_lsyncd":
		cwd => "/bin",
		command => "/sbin/chkconfig --add lsyncd",
		subscribe => File['/etc/init.d/lsyncd'],
	 }
	notify { 'done':
		message => "Lsyncd has been installed successfully. Edit the config file /etc/lsyncd.conf before starting the service.",
		loglevel => alert,
		subscribe => Exec['makeinstall_lsyncd'],
	}

}
