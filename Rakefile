# -*- coding: utf-8 -*-

# for ident(1)
CVS_ID = '$Id$'

require 'rbconfig'
include RbConfig

CONFIG['RUBY_INSTALL_NAME'] =~ /^(.*)ruby(.*)$/i or raise 'not found RUBY_INSTALL_NAME'
prefix = $1
suffix = $2

base_dir = File.join(File.dirname(__FILE__))
example = [ 'rackup', '-I', "#{base_dir}/lib", "#{base_dir}/run/config.ru" ]
gluon_local = [ "#{base_dir}/bin/gluon_local", '-d', base_dir ]

desc 'start example.'
task :example do
  sh example.join(' ')
end

desc 'unit-test.'
task :test do
  cd "#{base_dir}/test", :verbose => true do
    ruby 'run.rb'
  end
end

desc 'project local RubyGems.'
task :local_gem do
  ruby *gluon_local, "#{prefix}gem#{suffix} #{ENV['GEM_ARGS']}"
end

desc 'start example (project local RubyGems environemnt).'
task :local_example do
  ruby *gluon_local, *example
end

desc 'unit-test (project local RubyGems environemnt).'
task :local_test do
  cd "#{base_dir}/test", :verbose => true do
    ruby '../bin/gluon_local', '-d', '..', "#{prefix}rake#{suffix}"
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
