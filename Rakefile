# -*- coding: utf-8 -*-

load File.join(File.dirname(__FILE__), '.local_ruby_env')

def example(*options)
  [ 'rackup', '-I', get_project_libdir ] + options + get_command_options +
    [ "#{get_project_dir}/run/config.ru" ]
end

desc 'alias for example_develop.'
task :example => [ :example_develop ]

desc 'start example for development (rackup options for o1, o2, ...).'
task :example_develop do
  ENV['GLUON_ENV'] = 'development'
  sh *example('-E', 'development')
end

desc 'start example for deployment (rackup options for o1, o2, ...).'
task :example_deploy do
  ENV['GLUON_ENV'] = 'deployment'
  sh *example('-E', 'deployment')
end

desc 'unit-test.'
task :test do
  cd "#{get_project_dir}/test", :verbose => true do
    run_ruby_tool 'rake'
  end
end

rdoc_opts = [ '-SNa', '-m', 'Gluon', '-t', 'gluon - component based web application framework' ]

desc 'make document.'
task :rdoc do
  run_ruby_tool 'rdoc', *rdoc_opts, '-o', 'api', 'lib', 'run/lib'
end

desc 'alias for local_example_develop.'
task :local_example => [ :local_example_develop ]

desc 'start example for development (project local RubyGems environemnt).'
task :local_example_develop do
  ENV['GLUON_ENV'] = 'development'
  run_local_command *example('-E', 'development')
end

desc 'start example for deployment (project local RubyGems environemnt).'
task :local_example_deploy do
  ENV['GLUON_ENV'] = 'deployment'
  run_local_command *example('-E', 'deployment')
end

desc 'unit-test (project local RubyGems environemnt).'
task :local_test do
  cd "#{get_project_dir}/test", :verbose => true do
    run_ruby_tool 'rake', 'local_test'
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
  s.executables << 'gluon_setup' << 'gluon_example'
  s.files =
    %w[ ChangeLog Rakefile LICENSE EXAMPLE ] +
    Dir['{lib,run,test}/**/Rakefile'] +
    Dir['{lib,run,test}/**/*.{rb,erb,ru,cgi}'] +
    Dir['run/bin/cgi_server']
  s.test_files = [ 'test/run.rb' ]
  s.has_rdoc = true
  s.rdoc_options = rdoc_opts
  s.add_dependency 'rack'
}

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

desc 'clean garbage files'
task :clean => [ :clobber_package ] do
  rm_rf 'api'
  for f in Dir['**/*.erbc'] + Dir['*~']
    rm f
  end
  cd "#{get_project_dir}/test", :verbose => true do
    run_ruby_tool 'rake', 'clean'
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
