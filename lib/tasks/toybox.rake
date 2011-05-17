namespace :toybox do

  desc 'Initialize the project for debianization'
  task :init, :name, :version do |t, project|
    devel_debs = %w{build-essential cdbs debhelper sed make
                    devscripts dh-make dpatch dpkg-dev
                    fakeroot lintian}
    sh "sudo apt-get install #{devel_debs.join(' ')}"
    sh "dh_make -p #{project[:name]}_#{project[:version]} -b -n"
    puts "Removing example files from the debian/ folder"
    puts "If you read the above warning and understand it, press enter to continue"
    gets
    sh "find #{Rails.root}/debian -iname '*.ex' -exec rm {} \\;"
  end

  # Change the *.rake to be:
  # File.join(File.dirname(__FILE__), File.basename(__FILE__))
  file 'rules1.mk' => [File.join(File.dirname(__FILE__), File.basename(__FILE__)),'Rakefile','.'] do |t|
    puts 'building rules1.mk'
    s = files().map{|f| "\t@" + f.debian_install_cmd }
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
    dirs = dpkg_find do |path|
            if Kernel.test('d', path) and not Kernel.test('l',path) then
              path 
            end
    end
    open(t.name, 'w') do |io|
        dirs.each { |d1| io.puts "#{APP_ROOT}/#{d1}" }
    end 
  end

  task :files => Toybox.config[:files] do |t|
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
  task :debianize => [:user, :bundle, Toybox.config[:files]].flatten do |t|
    puts "building ..."
    sh 'dpkg-buildpackage -rfakeroot -uc -us '
  end

  desc 'submit last package to somewhere.'
  task :publish   do |t|
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
    Etc.getgrnam(Toybox.config[:group_name])
    Etc.getpwnam(Toybox.config[:username])
  end

  desc 'clean up'
  task :clean => [] do 
    sh 'dh_clean'
    [Toybox.config[:files], Toybox.config[:other_files]].flatten.each {|f| rm_f f }
    rm_f `ls debian/*.dirs`.strip
    #  rm_f 'build-stamp'
    #  rm_f 'install-stamp'
  end

  desc 'add a changelog entry - use version=0.0.0 to set version'
  task :changelog => [] do
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
