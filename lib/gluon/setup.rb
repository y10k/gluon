# setup utility

require 'fileutils'
require 'find'

module Gluon
  class Setup
    # for ident(1)
    CVS_ID = '$Id$'

    RUN_DIR = File.join(File.dirname(__FILE__), '..', '..', 'run')

    def initialize(install_dir)
      @install_dir = install_dir
    end

    def install_r(src_dir, target_dir)
      Find.find(src_dir) do |path|
        case (path)
        when /\.rb$|\.rhtml$/
          name = path[src_dir.length..-1]
          target_path = target_dir + name
          FileUtils.mkdir_p(File.dirname(target_path))
          FileUtils.install(path, target_path, :mode => 0644, :verbose => true)
        end
      end
    end
    private :install_r

    def install
      save_umask = File.umask(022)
      begin
        FileUtils.mkdir_p(@install_dir, :verbose => true)
        if (File.exist? File.join(@install_dir, 'config.rb')) then
          puts 'skip install config.rb'
        else
          FileUtils.install(File.join(RUN_DIR, 'config.rb'), @install_dir, :mode => 0644, :verbose => true)
        end

        bin_dir = File.join(@install_dir, 'bin')
        FileUtils.mkdir_p(bin_dir, :verbose => true)
        FileUtils.install(File.join(RUN_DIR, 'bin', 'run.rb'), bin_dir, :mode => 0755, :verbose => true)
        FileUtils.install(File.join(RUN_DIR, 'bin', 'run.cgi'), bin_dir, :mode => 0755, :verbose => true)

        lib_dir = File.join(@install_dir, 'lib')
        FileUtils.mkdir_p(lib_dir, :verbose => true)
        install_r(File.join(RUN_DIR, 'lib'), lib_dir)

        view_dir = File.join(@install_dir, 'view')
        FileUtils.mkdir_p(view_dir, :verbose => true)
        install_r(File.join(RUN_DIR, 'view'), view_dir)
      ensure
        File.umask(save_umask)
      end

      nil
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
