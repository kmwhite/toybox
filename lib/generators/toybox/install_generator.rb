require 'rails/generators/base'

module Toybox
  module Generators
    class InstallGenerator < Rails::Generators::Base

      desc 'Create initial config files for toybox'
      # see https://github.com/rspec/rspec-rails/blob/master/lib/generators/rspec.rb
      # for alternatives
      def self.source_root
        @source_root ||= File.expand_path("../templates", __FILE__)
      end

      # all public methods in here will be run in order
      def add_initializer_config
        template "toybox.rb", "config/initializers/toybox.rb"
      end
    end
  end
end
