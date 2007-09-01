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

        [ [ 'server', %w[ webrick mongrel ] ],
          [ 'cgi-bin', %w[ run.cgi ] ]
        ].each do |dir, targets|
          from_dir = File.join(RUN_DIR, dir)
          to_dir = File.join(@install_dir, dir)
          FileUtils.mkdir_p(to_dir, :verbose => true)
          for target in targets
            FileUtils.install(File.join(from_dir, target), to_dir, :mode => 0755, :verbose => true)
          end
        end

        %w[ lib view ].each do |dir|
          from_dir = File.join(RUN_DIR, dir)
          to_dir = File.join(@install_dir, dir)
          FileUtils.mkdir_p(to_dir, :verbose => true)
          install_r(from_dir, to_dir)
        end
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
