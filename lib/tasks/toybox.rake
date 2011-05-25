namespace :toybox do

  FILES = Toybox.config[:files]
  OTHER_FILES = Toybox.config[:other_files]

  desc 'Initialize the project for debianization'
  task :init, [:name, :version] => [:environment] do |t, project|
    unless (project[:name]&&project[:version]) 
      raise Exception.new("Need to provide name and version args!")
    end
    devel_debs = %w{build-essential cdbs debhelper sed make
                    devscripts dh-make dpatch dpkg-dev
                    fakeroot lintian}
    sh "sudo apt-get install #{devel_debs.join(' ')}"
    sh "dh_make -p #{project[:name]}_#{project[:version]} -b -n"
    puts "Removing example files from the debian/ folder"
    sh "find #{Rails.root}/debian -iname '*.ex' -exec rm {} \\;"
    File.open("#{Rails.root}/debian/rules",'w') do |f|
      f.puts <<EOF
#!/usr/bin/make -f

# include /usr/share/cdbs/1/rules/debhelper.mk
include /usr/share/cdbs/1/rules/buildvars.mk

PKG=$(DEB_SOURCE_PACKAGE)
LN=ln -sf

clean::
	@echo "clean me"
#	dh_testdir
#	dh_testroot
	rm -f build-stamp install-stamp
	-echo $(MAKE) clean
	dh_clean
	-rm debian/$(PKG).dirs

package-name:
	@echo DEB_SOURCE_PACKAGE=$(DEB_SOURCE_PACKAGE)

	
build: build-stamp

build-stamp:
	dh_testdir
	echo $(MAKE)
	touch build-stamp

install: install-stamp

install-stamp: build-stamp install-setup install-files install-links
	touch install-stamp

FAKEROOT=./debian/$(PKG)

debian/$(PKG).dirs: debian/package.dirs 
	@cp $< $@

install-setup: debian/$(PKG).dirs
	dh_testdir
	dh_testroot
	dh_clean -k
	mkdir  $(FAKEROOT) 
	( cd $(FAKEROOT) ; cat ../$(PKG).dirs | tr '\\n' '\\0'| xargs -0 -Ix install -d -m 755 x)
	#dh_installdirs
	#touch install-setup
	
include rules1.mk

install-links:
	@echo 1 >/dev/null

# Build architecture-independent files here.
# We have nothing to do 
binary-indep: build install
	@echo  nothing >/dev/null 

# Build architecture-dependent files here.
binary-arch: build install
	dh_testdir
	dh_testroot
	dh_installdocs
	dh_installinit -n --name=#{Toybox.config[:username]}
	dh_installinit -n --name=#{Toybox.config[:username]}-worker
	#  -u"start 2 3 . stop 11 1 ."
	dh_installcron
	dh_installman
	dh_link
	# dh_installchangelogs ChangeLog
	dh_installchangelogs 
	#dh_installdebconf
	# dh_strip
	# dh_fixperms
	chown cnuit:cnuit -R $(FAKEROOT)/#{Toybox.config[:app_root]}
	dh_compress
	dh_installdeb
	#dh_shlibdeps
	dh_gencontrol
	dh_md5sums
	dh_builddeb 

source diff:                                                                  
	@echo >&2 'source and diff are obsolete - use dpkg-source -b'; false

binary: binary-indep binary-arch
.PHONY: build clean binary-indep binary-arch binary
EOF

    end
  end

  # Change the *.rake to be:
  # File.join(File.dirname(__FILE__), File.basename(__FILE__))
  file 'rules1.mk' => [File.join(File.dirname(__FILE__), File.basename(__FILE__)),'Rakefile','.'] do |t|
    puts 'building rules1.mk'
    s = Toybox::files().map{|f| "\t@" + f.debian_install_cmd }
    open(t.name,'w') do |io|
      io.puts "#
# auto generated 
#
ifndef SRC
SRC=.
endif
install-files::"
      io.puts s
    end
  end

  file "debian/package.dirs" => [File.join(File.dirname(__FILE__), File.basename(__FILE__)),'Rakefile','.'] do |t|
    puts 'building debian/package.dirs file listing'
    dirs = Toybox::dpkg_find do |path|
            if Kernel.test('d', path) and not Kernel.test('l',path) then
              path 
            end
    end
    open(t.name, 'w') do |io|
        dirs.each { |d1| io.puts "#{Toybox.config[:app_root]}/#{d1}" }
    end 
  end

  task :files => ['debian/package.dirs', 'rules1.mk'] do |t|
      puts 'built files'
  end

  task :bundle do |t|
    Bundler.with_clean_env do
      puts "******************************************"
      puts "*        Warning: Running bundler        *"
      puts "*     Go drink a coffee or something     *"
      puts "******************************************"
      sh "bundle install --deployment --without test development"
    end
  end

  desc 'build debian package'
  task :debianize => [:environment, :user, :bundle, :files].flatten do |t|
    puts "building ..."
    sh 'dpkg-buildpackage -rfakeroot -uc -us '
  end

  desc 'submit last package to somewhere.'
  task :publish do |t|
    changelog = parsechangelog
    fn = "../#{debian_package(changelog)}"
    if Kernel.test('rf', fn) then 
      host = Toybox.config[:publish_host]
      sh "scp '#{fn}' '#{host}:' "
      sh "git commit -s -m'#{package_version} build changelog' debian/changelog" 
      pending_commits = %x[git log --pretty=oneline origin..master | wc -l].chomp.to_i
      if pending_commits == 1
        sh "git push"
        puts "\ndebian/changelog commited and pushed."
      else
        puts "\nYou have other pending commits. Please push the debian/changelog commit manually."
      end
    else
      raise "Error, can't find or read file #{fn}"
    end
  end

  task :user do |t|
    puts Toybox.config.inspect
    Etc.getgrnam(Toybox.config[:group_name])
    Etc.getpwnam(Toybox.config[:username])
  end

  desc 'clean up'
  task :clean => [:environment] do 
    sh 'dh_clean'
    [FILES, OTHER_FILES].flatten.each {|f| rm_f f }
    rm_f `ls debian/*.dirs`.strip
    #  rm_f 'build-stamp'
    #  rm_f 'install-stamp'
  end

  desc 'add a changelog entry - use version=0.0.0 to set version'
  task :changelog do #=> [] do
    v = find_ver(ENV)
    opt = "-i"
    opt = "-v #{v}" unless v.nil?
    distro = `lsb_release -i`
    if distro =~ /Ubuntu/ then
       distributor = "--distributor Debian"
    else
       distributor = ""
    end
    sh "dch --no-auto-nmu #{distributor} --distribution stable #{opt}"
  end
  desc 'list the version of the package from changelog'
  task :version => [] do
    puts package_version
  end

end #end of namespace
