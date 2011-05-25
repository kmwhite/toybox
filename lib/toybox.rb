module Toybox

  require 'etc'
  require 'find'
  require 'toybox/txtfile'
  require 'toybox/configfile'
  require 'toybox/exefile'
  require 'toybox/linkfile'

  @@config_data = {}

  class ToyboxTask < Rails::Railtie
    rake_tasks do
      Dir[File.join(File.dirname(__FILE__),'tasks/*.rake')].each { |f| load f }
    end
  end

  def self.app_fakeroot
    "$(FAKEROOT)/#{Toybox.config[:app_root]}"
  end

  def self.configure(config = nil, &block)
    # Given that we want things as they relate to the rails app,
    # the path given as config should be relative to Rails.root
    if config.is_a?(String) && config =~ /\S+\..yml/i then
      @@config_data = YAML::load_file(File.join(Rails.root, config)).freeze
    else
      @@config_data = (yield).freeze
    end
  end

  def self.config
    @@config_data
  end

  def self.is_non_production_yaml?(path)
    return false unless path =~ /\/config\/\w+\.yml$/ 
    if path =~ /\/config\/\w+_production\.yml$/ then
      false
    else
      true
    end
  end
  
  def self.filetype(path)
      return nil if Kernel.test('d', path) and not Kernel.test('l', path) 
      return nil if Toybox.config[:other_files].member? path 
      return nil if Toybox.config[:files].member? path 
      if Toybox.config[:use_production_yamls] then
        if is_non_production_yaml?(path) then
          STDERR.puts "skipping file: #{path}"
          return nil
        end 
      end
      return nil if path =~ /config.database.yml$/
      return nil if path =~ /config.ldap.yml$/
      if Kernel.test('l', path) then 
        Linkfile.new(path)
      elsif Kernel.test('x',path) then
        Exefile.new(path)
      elsif path =~ %r{^[\.\/]+config/} then
        Configfile.new(path)
      else
        Txtfile.new(path)
      end
  end
  
  def self.path_contains(path, arg)
    arg.each do |s|
      return true if path =~ Regexp.new(s)
    end
    false
  end
  
  def self.dpkg_find(&block)
    Toybox.config[:directories].map { |dir|
      f = []
      Find.find(dir) do |path|
        if Toybox.config[:prune_dirs].member? File.basename(path) and not path_contains(path, Toybox.config[:ignore_dirs]) then
          Find.prune
        elsif Toybox.config[:files].member? File.basename(path) then
          next
        elsif Toybox.config[:other_files].member? File.basename(path) then
          next
        elsif File.basename(path) =~ /^ruby_sess.*/ then
          next 
        else
          x = yield(path)
          f << x
        end
      end
      f.compact
    }.flatten.compact
  end
  
  def self.files()
    dpkg_find do |path|
      if path =~ /\.log$/ then
        nil  
      else
        filetype(path)
      end
    end
  end
  def self.parsechangelog
    changelog = %x{dpkg-parsechangelog}
    package, version = changelog.split("\n")[0,2].map{|x| x.split.last }
    arch = %x{dpkg-architecture -qDEB_HOST_ARCH}.chomp
    [ package, version, arch ] 
  end
  def self.debian_package(clog) 
    "#{clog.join('_')}.deb"
  end
  def self.package_version
    clog = parsechangelog
    clog[1]
  end

end
