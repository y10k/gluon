# = gluon - simple web application framework
#
# Author:: $Author$
# Date:: $Date$
# Revision:: $Revision$
#
# == license
#   :include:../LICENSE
#

require 'fileutils'
require 'find'
require 'optparse'

module Gluon
  class Setup
    # for ident(1)
    CVS_ID = '$Id$'

    RUNTIME = File.join(File.dirname(__FILE__), '..', '..', 'run')

    LIB_DIR    = 'lib'
    VIEW_DIR   = 'view'
    SERVER_DIR = 'server'
    CGI_DIR    = 'cgi-bin'

    UMASK_MODE = 0022
    EXEC_MODE  = 0755
    FILE_MODE  = 0644

    def initialize(install_dir, options={})
      @install_dir = install_dir
      @verbose = (options.key? :verbose) ? options[:verbose] : false
    end

    def make_top_dirs
      [ LIB_DIR,
        VIEW_DIR,
        SERVER_DIR,
        CGI_DIR,
      ].each do |top_dir|
        top_dir_path = File.join(@install_dir, top_dir)
        FileUtils.mkdir_p(top_dir_path, :verbose => @verbose)
      end
    end

    def install_runtime
      [ [ SERVER_DIR, EXEC_MODE, %w[ webrick mongrel ] ],
        [ SERVER_DIR, FILE_MODE, %w[ gluon.ru ] ],
        [ CGI_DIR,    EXEC_MODE, %w[ run.cgi ] ],
      ].each do |top_dir, mode, files|
        from_dir = File.join(RUNTIME, top_dir)
        to_dir = File.join(@install_dir, top_dir)
        for f in files
          from_path = File.join(from_dir, f)
          FileUtils.install(from_path, to_dir, :mode => mode, :verbose => @verbose)
        end
      end

      from_path = File.join(RUNTIME, 'Rakefile')
      to_dir = @install_dir
      FileUtils.install(from_path, to_dir, :mode => FILE_MODE, :verbose => @verbose)

      nil
    end

    def install_libraries(from_dir, to_dir)
      Find.find(from_dir) do |path|
        case (path)
        when /\.rb$/, /\.erb$/, /\.rhtml$/
          target_path = to_dir + path[from_dir.length..-1]
          target_dir = File.dirname(target_path)
          FileUtils.mkdir_p(target_dir)
          FileUtils.install(path, target_dir, :mode => FILE_MODE, :verbose => @verbose)
        end
      end
    end
    private :install_libraries

    def install_example
      [ LIB_DIR,
        VIEW_DIR
      ].each do |top_dir|
        from_dir = File.join(RUNTIME, top_dir)
        to_dir = File.join(@install_dir, top_dir)
        install_libraries(from_dir, to_dir)
      end

      from_conf = File.join(RUNTIME, 'config.rb')
      to_dir = @install_dir
      FileUtils.install(from_conf, to_dir, :mode => FILE_MODE, :verbose => @verbose)

      nil
    end

    class << self
      def config_parse(text)
        parsed_alist = []
        in_example = false
        text.each_line do |line|
          case (line)
          when /:example:start/
            parsed_alist << [ :example_start, line ]
            in_example = true
          when /:example:stop/
            parsed_alist << [ :example_stop, line ]
            in_example = false
          else
            if (in_example) then
              parsed_alist << [ :example, line ]
            else
              parsed_alist << [ :line, line ]
            end
          end
        end

        parsed_alist
      end

      def config_render(parsed_alist)
        rendered_text = ''
        for tag, line in parsed_alist
          case (tag)
          when :example
            rendered_text << '# ' << line
          else
            rendered_text << line
          end
        end

        rendered_text
      end
    end

    def install_config
      from_path = File.join(RUNTIME, 'config.rb')
      to_path = File.join(@install_dir, 'config.rb')
      if (File.exist? to_path) then
        to_path += '.new'
      end

      config_text = File.open(from_path, 'r') {|r|
        r.binmode
        r.read
      }

      config_rendered =
        Setup.config_render(
          Setup.config_parse(config_text))

      File.open(to_path, 'w') {|w|
        w.binmode
        w.write(config_rendered)
      }

      FileUtils.chmod(FILE_MODE, to_path, :verbose => @verbose)

      nil
    end

    class << self
      def umask
        save_umask = File.umask(UMASK_MODE)
        begin
          yield
        ensure
          File.umask(save_umask)
        end
      end

      def common_options
        options = {
          :target_directory => nil,
          :verbose => true
        }

        opts = OptionParser.new
        opts.on('-d', '--target-directory=DIRECTORY', String) {|value|
          options[:target_directory] = value
        }
        opts.on('-v', '--[no-]verbose') {|value|
          if (value) then
            options[:verbose] = true
          else
            options[:verbose] = false
          end
        }
        opts.on('-q', '--quiet') {
          options[:verbose] = false
        }

        return options, opts
      end
    end

    def command_setup
      Setup.umask{
        make_top_dirs
        install_runtime
        install_config
      }
      nil
    end

    def command_example
      Setup.umask{
        make_top_dirs
        install_runtime
        install_example
      }
      nil
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
