module Toybox

  require 'etc'
  require 'find'
  require 'toybox/txtfile'
  require 'toybox/configfile'
  require 'toybox/exefile'
  require 'toybox/linkfile'

  @@config_data = {}

  APP_FAKEROOT =  "$(FAKEROOT)/#{@@config_data[:app_root]}"

  class ToyboxTask < Rails::Railtie
    rake_tasks do
      Dir[File.join(File.dirname(__FILE__),'tasks/*.rake')].each { |f| load f }
    end
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

end
