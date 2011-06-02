# toybox

Toybox is a simple gem to help package Rails Applications as Debian Packages for easy distribution and scripted spin-ups of nodes.

## Installation

Simply add:
        gem 'toybox'
to your Gemfile

## Usage

### Create the generator
        rails generate toybox:config
### Edit the generated config
        $EDITOR config/initializers/toybox.rb
### Initialize the application
        rake toybox:init['foo','1.0']
### Edit the config
        $EDITOR debian/control
### Debianize!
        rake toybox:debianize


## Contributing to toybox
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 Kristofer M White. See LICENSE.txt for
further details.

