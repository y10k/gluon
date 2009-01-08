# for ident(1)
CVS_ID = '$Id$'

BIN_DIR = 'bin'
LIB_DIR = 'lib'
TEST_DIR = 'test'
RDOC_DIR = 'api'
RDOC_OPTS = %w[ -SNa -m Gluon ]
RUNTIME_DIR = 'run'

def cd_v(dir)
  cd(dir, :verbose => true) {
    yield
  }
end

def runtime
  cd_v(RUNTIME_DIR) {
    if (ENV.key? 'RUBYLIB') then
      ENV['RUBYLIB'] += ":../#{LIB_DIR}"
    else
      ENV['RUBYLIB'] = "../#{LIB_DIR}"
    end
    yield
  }
end

task :default => [ :package ]

desc 'unit-test.'
task :test do
  cd_v(TEST_DIR) {
    sh 'rake'
  }
end

desc 'create document.'
task :rdoc do
  cd_v(LIB_DIR) {
    sh 'rdoc', '-o', "../#{RDOC_DIR}", *RDOC_OPTS
  }
end

desc 'start example.'
task :example do
  runtime{
    sh 'rake', 'run'
  }
end

desc 'start example for debug.'
task :debug do
  runtime{
    sh 'rake', 'debug'
  }
end

require 'rake/gempackagetask'
require 'lib/gluon/version'
spec = Gem::Specification.new{|s|
  s.name = 'gluon'
  s.version = Gluon::VERSION
  s.summary = 'simple web application framework'
  s.author = 'TOKI Yoshinori'
  s.email = 'toki@freedom.ne.jp'
  s.executables << 'gluon_setup' << 'gluon_example'
  s.files =
    %w[ ChangeLog Rakefile lib/LICENSE ] +
    Dir['{lib,run,test}/**/Rakefile'] +
    Dir['{lib,run,test}/**/*.{rb,rhtml,erb,cgi}'] +
    Dir['run/server/{mongrel,webrick,webrick_cgi}']
  s.test_files = [ 'test/run.rb' ]
  s.has_rdoc = true
  s.rdoc_options = RDOC_OPTS
}
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

desc 'install.'
task :gem_install => [ :gem ] do
  sh 'gem', 'install', "pkg/gluon-#{Gluon::VERSION}.gem"
end

desc 'clean up work files.'
task :clean => [ :clobber_package ] do
  rm_rf RDOC_DIR
  cd_v('test') {
    sh 'rake', 'clean'
  }
end

desc 'clean up all work files.'
task :clean_all => :clean do
  rm_rf EXAMPLE_DIR
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
