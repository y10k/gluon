#!/usr/local/bin/ruby

require 'fileutils'
require 'gluon'
require 'test/unit'

module Gluon::Test
  class SetupTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    def setup
      @install_dir = 'setup_install_test_dir'
      FileUtils.rm_rf(@install_dir) if $DEBUG
      @setup = Gluon::Setup.new(@install_dir)
      @saved_umask = File.umask
    end

    def teardown
      File.umask(@saved_umask)
      FileUtils.rm_rf(@install_dir) unless $DEBUG
    end

    def inst_path(*names)
      File.join(@install_dir, *names)
    end
    private :inst_path

    def test_make_toip_dirs
      @setup.make_top_dirs
      assert(File.directory? inst_path(Gluon::Setup::LIB_DIR))
      assert(File.directory? inst_path(Gluon::Setup::VIEW_DIR))
      assert(File.directory? inst_path(Gluon::Setup::SERVER_DIR))
      assert(File.directory? inst_path(Gluon::Setup::CGI_DIR))
    end

    def test_install_runtime
      @setup.make_top_dirs
      @setup.install_runtime

      assert(File.file? inst_path(Gluon::Setup::SERVER_DIR, 'webrick'))
      assert(File.executable? inst_path(Gluon::Setup::SERVER_DIR, 'webrick'))

      assert(File.file? inst_path(Gluon::Setup::SERVER_DIR, 'mongrel'))
      assert(File.executable? inst_path(Gluon::Setup::SERVER_DIR, 'mongrel'))

      assert(File.file? inst_path(Gluon::Setup::SERVER_DIR, 'gluon.ru'))
      assert(! (File.executable? inst_path(Gluon::Setup::SERVER_DIR, 'gluon.ru')))

      assert(File.file? inst_path(Gluon::Setup::CGI_DIR, 'run.cgi'))
      assert(File.executable? inst_path(Gluon::Setup::CGI_DIR, 'run.cgi'))
    end

    def test_install_example
      @setup.make_top_dirs
      @setup.install_example
      assert(File.file? inst_path(Gluon::Setup::LIB_DIR, 'Welcom.rb'))
      assert(File.file? inst_path(Gluon::Setup::VIEW_DIR, 'Welcom.erb'))
      assert(File.file? inst_path('config.rb'))
      assert(FileUtils.cmp(File.join(Gluon::Setup::RUNTIME, 'config.rb'),
                           inst_path('config.rb')))
    end

    def test_config_parse
      config_text =  "foo\n"
      config_text << ":example:start\n"
      config_text << "bar\n"
      config_text << ":example:stop\n"
      config_text << "baz\n"

      assert_equal([ [ :line,           "foo\n" ],
                     [ :example_start , ":example:start\n" ],
                     [ :example,        "bar\n" ],
                     [ :example_stop,   ":example:stop\n" ],
                     [ :line,           "baz\n" ]
                   ],
                   Gluon::Setup.config_parse(config_text))
                     
    end

    def test_config_render
      config_alist = [
        [ :line,           "foo\n" ],
        [ :example_start , ":example:start\n" ],
        [ :example,        "bar\n" ],
        [ :example_stop,   ":example:stop\n" ],
        [ :line,           "baz\n" ]
      ]

      config_expected =  "foo\n"
      config_expected << ":example:start\n"
      config_expected << "# bar\n"
      config_expected << ":example:stop\n"
      config_expected << "baz\n"

      assert_equal(config_expected,
                   Gluon::Setup.config_render(config_alist))
    end

    def test_config_parse_render
      config_text =  "foo\n"
      config_text << ":example:start\n"
      config_text << "bar\n"
      config_text << ":example:stop\n"
      config_text << "baz\n"

      config_expected =  "foo\n"
      config_expected << ":example:start\n"
      config_expected << "# bar\n"
      config_expected << ":example:stop\n"
      config_expected << "baz\n"

      assert_equal(config_expected,
                   Gluon::Setup.config_render(
                     Gluon::Setup.config_parse(config_text)))
    end

    def test_install_config
      @setup.make_top_dirs
      @setup.install_config
      assert(File.file? inst_path('config.rb'))
      assert(! (File.executable? inst_path('config.rb')))
      assert(! FileUtils.cmp(File.join(Gluon::Setup::RUNTIME, 'config.rb'),
                             inst_path('config.rb')))
    end

    def test_install_config2
      @setup.make_top_dirs
      FileUtils.touch(inst_path('config.rb'))
      @setup.install_config
      assert(File.file? inst_path('config.rb.new'))
      assert(! (File.executable? inst_path('config.rb.new')))
      assert(! FileUtils.cmp(File.join(Gluon::Setup::RUNTIME, 'config.rb'),
                             inst_path('config.rb.new')))
    end

    def test_umask
      assert_not_equal(0777, Gluon::Setup::UMASK_MODE)
      File.umask(0777)
      count = 0
      r = Gluon::Setup.umask{
        assert_equal(Gluon::Setup::UMASK_MODE, File.umask)
        count += 1
        'result'
      }
      assert_equal(1, count)
      assert_equal('result', r)
      assert_equal(0777, File.umask)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
