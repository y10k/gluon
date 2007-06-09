# setup utility

require 'fileutils'

module Gluon
  class Setup
    # for ident(1)
    CVS_ID = '$Id$'

    RUN_DIR = File.join(File.dirname(__FILE__), '..', '..', 'run')

    def initialize(install_dir)
      @install_dir = install_dir
    end

    def install
      save_umask = File.umask(022)
      begin
	FileUtils.mkdir_p(@install_dir, :verbose => true)
	FileUtils.install(File.join(RUN_DIR, 'config.rb'), @install_dir, :mode => 0644, :verbose => true)

	bin_dir = File.join(@install_dir, 'bin')
	FileUtils.mkdir_p(bin_dir)
	FileUtils.install(File.join(RUN_DIR, 'bin', 'run.rb'), bin_dir, :mode => 0755, :verbose => true)
	FileUtils.install(File.join(RUN_DIR, 'bin', 'run.cgi'), bin_dir, :mode => 0755, :verbose => true)

	lib_dir = File.join(@install_dir, 'lib')
	FileUtils.mkdir_p(lib_dir)
	FileUtils.install(File.join(RUN_DIR, 'lib', 'Welcom.rb'), lib_dir, :mode => 0644, :verbose => true)

	view_dir = File.join(@install_dir, 'view')
	FileUtils.mkdir_p(view_dir)
	FileUtils.install(File.join(RUN_DIR, 'view', 'Welcom.rhtml'), view_dir, :mode => 0644, :verbose => true)
      ensure
	File.umask(save_umask)
      end

      nil
    end
  end
end
