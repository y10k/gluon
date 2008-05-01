# for ident(1)
CVS_ID = '$Id$'

BIN_DIR = 'bin'
LIB_DIR = 'lib'
TEST_DIR = 'test'
RDOC_DIR = 'api'
RDOC_MAIN = 'gluon.rb'
EXAMPLE_DIR = 'welcom'
GLUON_SETUP = File.join(BIN_DIR, 'gluon_setup')
GLUON_UPDATE = File.join(BIN_DIR, 'gluon_update')

def cd_v(dir)
  cd(dir, :verbose => true) {
    yield
  }
end

task :default

task :test do
  cd_v(TEST_DIR) {
    sh 'rake'
  }
end

task :rdoc do
  cd_v(LIB_DIR) {
    sh 'rdoc', '-a', '-i', '..', '-o', "../#{RDOC_DIR}", '-m', RDOC_MAIN
  }
end

task :example => [ :example_install ] do
  sv_type = ENV['SERVER'] || 'webrick'
  ruby '-I', LIB_DIR, "#{EXAMPLE_DIR}/server/#{sv_type}"
end

task :example_install do
  rm_f "#{EXAMPLE_DIR}/config.rb"
  ruby '-I', LIB_DIR, GLUON_SETUP, EXAMPLE_DIR
end

task :example_update do
  ruby '-I', LIB_DIR, GLUON_UPDATE, EXAMPLE_DIR
end

require 'rake/gempackagetask'
require 'lib/gluon/version'
spec = Gem::Specification.new{|s|
  s.name = 'gluon'
  s.version = Gluon::VERSION
  s.summary = 'simple web application framework'
  s.author = 'TOKI Yoshinori'
  s.email = 'toki@freedom.ne.jp'
  s.executables << 'gluon_setup' << 'gluon_update'
  s.files = Dir['{lib,run,test}/**/*.{rb,rhtml,cgi}'] +
    %w[ gluon.ru webrick mongrel ].map{|i| "run/server/#{i}" }
  s.files << 'ChangeLog' << 'Rakefile'
  s.test_files = [ 'test/run.rb' ]
  s.has_rdoc = false
}
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

task :gem_install => [ :gem ] do
  sh 'gem', 'install', "pkg/gluon-#{Gluon::VERSION}.gem"
end

task :clean => [ :clobber_package ] do
  rm_rf RDOC_DIR
end

task :clean_all => :clean do
  rm_rf EXAMPLE_DIR
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
