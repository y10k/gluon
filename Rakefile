# -*- coding: utf-8 -*-

# for ident(1)
CVS_ID = '$Id$'

require 'rbconfig'
include RbConfig

base_dir = File.join(File.dirname(__FILE__))

desc 'start example.'
task :example do
  ruby "#{base_dir}/bin/gluon_local", '-d', base_dir,
    'rackup', '-I', "#{base_dir}/lib", '-I', "#{base_dir}/run/lib", "#{base_dir}/run/config.ru"
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
