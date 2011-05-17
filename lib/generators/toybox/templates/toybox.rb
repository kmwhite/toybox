Toybox.configure do
  {
    # app_root: the path to the final resting place of your
    # package's data. Do not include the initial slash ('/')
    :app_root => 'path/to/app/root',

    # publish_host: the ssh-able host to publish the file to
    :publish_host => 'somewhere.yourdomain.com',

    # username: The user the app is to be owned by
    :username => 'some_user',

    # group_name: The group the app is to be owned by
    :group_name => 'some_group',

    # files: description to be added (TODO)
    :files => [
      'debian/package.dirs',
      'rules1.mk'
    ], 

    # other_files: description to be added (TODO)
    :other_files => [
      'build-stamp',
      'install-stamp'
    ],

    # directories: description to be added (TODO)
    :directories => [
      '.'
    ],

    # prune_dirs: Directories to be pruned out
    :prune_dirs => [
      '.git',
      'debian',
      'test'
    ],

    # ignore_dirs: Directories to be included, even if they
    # match the pattern of a prune dir. This is to assert
    # that if, for instance, you have listed test in prune_dirs
    # to remove the tests from the debian package, but an installed
    # bundle contains the word test (think Rack::Test), it doens't
    # prune it
    :ignore_dirs => [
      'vendor/bundle',
      'vendor/plugins'
    ]
  }
end
