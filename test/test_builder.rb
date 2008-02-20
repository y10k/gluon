#!/usr/local/bin/ruby

require 'digest'
require 'gluon'
require 'test/unit'

module Gluon::Test
  class BuilderTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    def setup
      @base_dir = File.dirname(__FILE__)
      @view_dir = File.join(@base_dir, 'view')
      @conf_path = File.join(@base_dir, 'config_test.rb')
      @builder = Gluon::Builder.new(:base_dir => @base_dir,
                                    :view_dir => @view_dir,
                                    :conf_path => @conf_path)
    end

    def test_attributes
      assert_equal(@base_dir, @builder.base_dir)
      assert_equal(@view_dir, @builder.view_dir)
      assert_equal(@conf_path, @builder.conf_path)
      assert_equal({}, @builder.session_conf.options)
    end

    def test_config_access_log
      @builder.eval_conf %q{
        access_log 'foo.log'
      }
      assert_equal('foo.log', @builder.access_log)
    end

    def test_config_port
      @builder.eval_conf %q{
        port 80
      }
      assert_equal(80, @builder.port)
    end

    class Foo
    end

    def test_config_mount
      @builder.eval_conf %Q{
        mount #{Foo}, '/foo'
      }
      assert_equal(Foo, @builder.find('/foo'))
    end

    def test_config_initial_plugin
      @builder.eval_conf %q{
        initial do
          plugin :_foo => 'foo plugin'
          plugin :_bar do
            'bar plugin'
          end
        end
      }
      assert_equal('foo plugin', @builder.plugin_get(:_foo))
      assert_equal('bar plugin', @builder.plugin_get(:_bar))
      @builder.plugin_get(:_foo) {|value|
        assert_equal('foo plugin', value)
      }
      @builder.plugin_get(:_bar) {|value|
        assert_equal('bar plugin', value)
      }
    end

    def test_config_session_default_key
      @builder.eval_conf %q{
        session do
          default_key 'foo'
        end
      }
      assert_equal({ :default_key => 'foo' },
                   @builder.session_conf.options)
    end

    def test_config_session_default_domain
      @builder.eval_conf %q{
        session do
          default_domain 'www.foo.net'
        end
      }
      assert_equal({ :default_domain => 'www.foo.net' },
                   @builder.session_conf.options)
    end

    def test_config_session_default_path
      @builder.eval_conf %q{
        session do
          default_path '/foo'
        end
      }
      assert_equal({ :default_path => '/foo' },
                   @builder.session_conf.options)
    end

    def test_config_session_id_max_length
      @builder.eval_conf %q{
        session do
          id_max_length 100
        end
      }
      assert_equal({ :id_max_length => 100 },
                   @builder.session_conf.options)
    end

    def test_config_session_time_to_live
      @builder.eval_conf %q{
        session do
          time_to_live 60 * 5
        end
      }
      assert_equal({ :time_to_live => 60 * 5 },
                   @builder.session_conf.options)
    end

    def test_config_session_auto_expire
      @builder.eval_conf %q{
        session do
          auto_expire true
        end
      }
      assert_equal({ :auto_expire => true },
                   @builder.session_conf.options)
    end

    def test_config_session_digest
      @builder.eval_conf %q{
        session do
          digest Digest::SHA512
        end
      }
      assert_equal({ :digest => Digest::SHA512 },
                   @builder.session_conf.options)
    end

    def test_config_session_store
      @builder.eval_conf %q{
        session do
          store :DummyStore
        end
      }
      assert_equal({ :store => :DummyStore },
                   @builder.session_conf.options)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
