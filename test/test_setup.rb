#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'fileutils'
require 'gluon'
require 'test/unit'

module Gluon::Test
  class SetupTest < Test::Unit::TestCase
    def setup
      @install_dir = nil
      @saved_umask = File.umask
    end

    def teardown
      File.umask(@saved_umask)
    end

    def setup_test_dir(name)
      @install_dir = File.join(File.dirname(__FILE__), File.basename(__FILE__, '.rb') + ".#{name}.install")
      @setup = Gluon::Setup.new(@install_dir)
      FileUtils.rm_rf(@install_dir)
      FileUtils.mkdir(@install_dir)
    end
    private :setup_test_dir

    def test_make_top_dirs
      setup_test_dir('test_make_top_dirs')
      @setup.make_top_dirs
      assert(File.directory? File.join(@install_dir, Gluon::Setup::BIN_DIR))
      assert(File.directory? File.join(@install_dir, Gluon::Setup::CGI_DIR))
      assert(File.directory? File.join(@install_dir, Gluon::Setup::LIB_DIR))
      assert(File.directory? File.join(@install_dir, Gluon::Setup::VIEW_DIR))
      assert(File.directory? File.join(@install_dir, Gluon::Setup::TEST_DIR))
    end

    def test_install_runtime
      setup_test_dir('test_install_runtime')
      @setup.make_top_dirs
      @setup.install_runtime

      assert(File.file? File.join(@install_dir, Gluon::Setup::BIN_DIR, 'cgi_server'))
      assert(File.executable? File.join(@install_dir, Gluon::Setup::BIN_DIR, 'cgi_server'))

      assert(File.file? File.join(@install_dir, Gluon::Setup::CGI_DIR, 'gluon.cgi'))
      assert(File.executable? File.join(@install_dir, Gluon::Setup::CGI_DIR, 'gluon.cgi'))

      assert(File.file? File.join(@install_dir, Gluon::Setup::CGI_DIR, 'config.ru'))
      assert(! (File.executable? File.join(@install_dir, Gluon::Setup::CGI_DIR, 'config.ru')))

      assert(File.file? File.join(@install_dir, Gluon::Setup::TEST_DIR, 'run.rb'))
      assert(File.executable? File.join(@install_dir, Gluon::Setup::TEST_DIR, 'run.rb'))

      assert(File.file? File.join(@install_dir, Gluon::Setup::TEST_DIR, 'Rakefile'))
      assert(! (File.executable? File.join(@install_dir, Gluon::Setup::TEST_DIR, 'Rakefile')))

      assert(File.file? File.join(@install_dir, '.local_ruby_env'))
      assert(! (File.executable? File.join(@install_dir, '.local_ruby_env')))

      assert(File.file? File.join(@install_dir, 'Rakefile'))
      assert(! (File.executable? File.join(@install_dir, 'Rakefile')))

      assert(File.file? File.join(@install_dir, 'config.ru'))
      assert(! (File.executable? File.join(@install_dir, 'config.ru')))

      assert(! (File.file? File.join(@install_dir, 'config.rb')),
             'customizable configuration file should not exist.')
    end

    def test_install_example
      setup_test_dir('test_install_example')
      @setup.make_top_dirs
      @setup.install_example

      assert(File.file? File.join(@install_dir, Gluon::Setup::LIB_DIR, 'Welcom.rb'))
      assert(! (File.executable? File.join(@install_dir, Gluon::Setup::LIB_DIR, 'Welcom.rb')))

      assert(File.file? File.join(@install_dir, Gluon::Setup::VIEW_DIR, 'Welcom.erb'))
      assert(! (File.executable? File.join(@install_dir, Gluon::Setup::VIEW_DIR, 'Welcom.erb')))

      assert(File.file? File.join(@install_dir, 'config.rb'))
      assert(! (File.executable? File.join(@install_dir, 'config.rb')))
      assert(FileUtils.cmp(File.join(Gluon::Setup::RUNTIME_DIR, 'config.rb'),
                           File.join(@install_dir, 'config.rb')))
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

    def test_config_comment_out_example
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
                   Gluon::Setup.config_comment_out_example(config_alist))
    end

    def test_config_parse_comment_out_example
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
                   Gluon::Setup.config_comment_out_example(
                     Gluon::Setup.config_parse(config_text)))
    end

    def test_install_config
      setup_test_dir('test_install_config')
      @setup.make_top_dirs
      @setup.install_config

      assert(File.file? File.join(@install_dir, 'config.rb'))
      assert(! (File.executable? File.join(@install_dir, 'config.rb')))
      assert(! FileUtils.cmp(File.join(Gluon::Setup::RUNTIME_DIR, 'config.rb'),
                             File.join(@install_dir, 'config.rb')))
    end

    def test_install_config_not_overwrite
      setup_test_dir('test_install_config_not_overwrite')
      @setup.make_top_dirs
      FileUtils.touch(File.join(@install_dir, 'config.rb'))
      @setup.install_config

      assert_equal(0, File.stat(File.join(@install_dir, 'config.rb')).size,
                   'should not modified original config.rb')

      assert(File.file? File.join(@install_dir, 'config.rb.new'))
      assert(! (File.executable? File.join(@install_dir, 'config.rb.new')))
      assert(! FileUtils.cmp(File.join(Gluon::Setup::RUNTIME_DIR, 'config.rb'),
                             File.join(@install_dir, 'config.rb.new')))
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
