# setup utility

require 'fileutils'
require 'find'

module Gluon
  class Setup
    # for ident(1)
    CVS_ID = '$Id$'

    RUN_DIR = File.join(File.dirname(__FILE__), '..', '..', 'run')

    SERVER_DIR = 'server'
    CGI_DIR = 'cgi-bin'
    LIB_DIR = 'lib'
    VIEW_DIR = 'view'

    UMASK_MODE = 0022
    EXEC_MODE = 0755
    FILE_MODE = 0644

    def initialize(install_dir)
      @install_dir = install_dir
    end

    def make_top_dirs
      [ SERVER_DIR,
        CGI_DIR,
        LIB_DIR,
        VIEW_DIR
      ].each do |name|
        FileUtils.mkdir_p(File.join(@install_dir, name), :verbose => true)
      end
    end
    private :make_top_dirs

    def install_runtime
      [ [ SERVER_DIR, %w[ webrick mongrel ], EXEC_MODE ],
        [ SERVER_DIR, %w[ gluon.ru ], FILE_MODE ],
        [ CGI_DIR, %w[ run.cgi ], EXEC_MODE ]
      ].each do |top_dir, targets, mode|
        from_dir = File.join(RUN_DIR, top_dir)
        to_dir = File.join(@install_dir, top_dir)
        for target in targets
          FileUtils.install(File.join(from_dir, target), to_dir, :mode => mode, :verbose => true)
        end
      end
      nil
    end
    private :install_runtime

    def install_libraries(src_dir, target_dir)
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
    private :install_libraries

    def install_example
      [ LIB_DIR,
        VIEW_DIR
      ].each do |top_dir|
        from_dir = File.join(RUN_DIR, top_dir)
        to_dir = File.join(@install_dir, top_dir)
        install_libraries(from_dir, to_dir)
      end
      nil
    end
    private :install_example

    def install_config
      src_path = File.join(RUN_DIR, 'config.rb')
      dst_path = File.join(@install_dir, 'config.rb')
      if (File.exist? dst_path) then
        puts 'skip install config.rb'
      else
        FileUtils.install(src_path, dst_path, :mode => FILE_MODE, :verbose => true)
      end
      nil
    end
    private :install_config

    def umask
      save_umask = File.umask(UMASK_MODE)
      begin
        yield
      ensure
        File.umask(save_umask)
      end
    end
    private :umask

    def install
      umask{
        make_top_dirs
        install_runtime
        install_example
        install_config
      }
      nil
    end

    def update
      umask{
        make_top_dirs
        install_runtime
      }
      nil
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
