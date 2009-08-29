# -*- coding: utf-8 -*-

# for ident(1)
CVS_ID = '$Id$'

require 'rbconfig'
include RbConfig

CONFIG['RUBY_INSTALL_NAME'] =~ /^(.*)ruby(.*)$/i or raise 'not found RUBY_INSTALL_NAME'
prefix = $1
suffix = $2

base_dir = File.join(File.dirname(__FILE__))
gluon_local = [ "#{base_dir}/bin/gluon_local", '-d', base_dir ]
example = [ 'rackup', '-I', "#{base_dir}/lib", "#{base_dir}/run/config.ru" ]

desc 'start example.'
task :example do
  sh example.join(' ')
end

desc 'unit-test.'
task :test do
  cd "#{base_dir}/test", :verbose => true do
    sh "#{prefix}rake#{suffix}"
  end
end

desc 'project local RubyGems (optional parameters: GEM_ARGS).'
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

require 'lib/gluon/version'
require 'rake/gempackagetask'
spec = Gem::Specification.new{|s|
  s.name = 'gluon'
  s.version = Gluon::VERSION
  s.summary = 'component based web application framework'
  s.author = 'TOKI Yoshinori'
  s.email = 'toki@freedom.ne.jp'
  s.executables << 'gluon_setup' << 'gluon_example' << 'gluon_local'
  s.files =
    %w[ ChangeLog Rakefile lib/LICENSE ] +
    Dir['{lib,run,test}/**/Rakefile'] +
    Dir['{lib,run,test}/**/*.{rb,erb,ru,cgi}'] +
    Dir['run/bin/cgi_server']
  s.test_files = [ 'test/run.rb' ]
  s.has_rdoc = true
  s.rdoc_options = %w[ -SNa -m Gluon ]
}
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

desc 'clean garbage files'
task :clean => [ :clobber_package ] do
  cd "#{base_dir}/test", :verbose => true do
    sh "#{prefix}rake#{suffix} clean"
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
