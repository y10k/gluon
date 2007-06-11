# for ident(1)
CVS_ID = '$Id$'

LIB_DIR = 'lib'
TEST_DIR = 'test'
RDOC_DIR = 'api'
RDOC_MAIN = 'gluon.rb'

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

require 'rake/gempackagetask'
spec = Gem::Specification.new{|s|
  s.name = 'gluon'
  s.version = '0.0.0'
  s.summary = 'transactional storage'
  s.author = 'TOKI Yoshinori'
  s.email = 'toki@freedom.ne.jp'
  s.executables << 'gluon_setup'
  s.files = Dir['{lib,run,test}/**/*.{rb,rhtml,cgi}'] << 'ChangeLog' << 'Rakefile'
  s.test_files = [ 'test/run.rb' ]
  s.has_rdoc = false
}
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

task :clean => [ :clobber_package ] do
  rm_rf RDOC_DIR
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
