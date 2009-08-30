# -*- coding: utf-8 -*-
# = gluon - simple web application framework
# == license
#   :include:../LICENSE
#

require 'fileutils'
require 'find'
require 'optparse'

module Gluon
  class Setup
    BASE_DIR = File.join(File.dirname(__FILE__), '..', '..')
    RUNTIME_DIR = File.join(BASE_DIR, 'run')

    BIN_DIR    = 'bin'
    CGI_DIR    = 'cgi-bin'
    LIB_DIR    = 'lib'
    VIEW_DIR   = 'view'

    UMASK_MODE = 0022
    EXEC_MODE  = 0755
    FILE_MODE  = 0644

    def initialize(install_dir, options={})
      @install_dir = install_dir
      @verbose = (options.key? :verbose) ? options[:verbose] : false
    end

    def make_top_dirs
      [ BIN_DIR,
        CGI_DIR,
        LIB_DIR,
        VIEW_DIR
      ].each do |top_dir|
        top_dir_path = File.join(@install_dir, top_dir)
        FileUtils.mkdir_p(top_dir_path, :verbose => @verbose)
      end
    end

    def install_runtime
      FileUtils.install(File.join(BASE_DIR, 'bin', 'gluon_local'),
                        File.join(@install_dir, BIN_DIR), :mode => EXEC_MODE, :verbose => @verbose)
      FileUtils.install(File.join(RUNTIME_DIR, BIN_DIR, 'cgi_server'),
                        File.join(@install_dir, BIN_DIR), :mode => EXEC_MODE, :verbose => @verbose)
      FileUtils.install(File.join(RUNTIME_DIR, CGI_DIR, 'gluon.cgi'),
                        File.join(@install_dir, CGI_DIR), :mode => EXEC_MODE, :verbose => @verbose)
      FileUtils.install(File.join(RUNTIME_DIR, CGI_DIR, 'config.ru'),
                        File.join(@install_dir, CGI_DIR), :mode => FILE_MODE, :verbose => @verbose)
      FileUtils.install(File.join(RUNTIME_DIR, 'Rakefile'), @install_dir, :mode => FILE_MODE, :verbose => @verbose)
      FileUtils.install(File.join(RUNTIME_DIR, 'config.ru'), @install_dir, :mode => FILE_MODE, :verbose => @verbose)

      nil
    end

    def install_libraries(from_dir, to_dir)
      Find.find(from_dir) do |path|
        case (path)
        when /\.rb$/, /\.erb$/
          target_path = to_dir + path[from_dir.length..-1]
          target_dir = File.dirname(target_path)
          FileUtils.mkdir_p(target_dir)
          FileUtils.install(path, target_dir, :mode => FILE_MODE, :verbose => @verbose)
        end
      end
    end
    private :install_libraries

    def install_example
      install_libraries(File.join(RUNTIME_DIR, LIB_DIR), File.join(@install_dir, LIB_DIR))
      install_libraries(File.join(RUNTIME_DIR, VIEW_DIR), File.join(@install_dir, VIEW_DIR))
      FileUtils.install(File.join(RUNTIME_DIR, 'config.rb'), @install_dir, :mode => FILE_MODE, :verbose => @verbose)

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

      def config_comment_out_example(parsed_alist)
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
      install_path = File.join(@install_dir, 'config.rb')
      install_path += '.new' if (File.exist? install_path)
      config_template = File.open(File.join(RUNTIME_DIR, 'config.rb'), "r:#{__ENCODING__}") {|r| r.read }
      config_text = Setup.config_comment_out_example(Setup.config_parse(config_template))
      File.open(install_path, "w:#{__ENCODING__}") {|w| w.write(config_text) }
      FileUtils.chmod(FILE_MODE, install_path, :verbose => @verbose)

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
