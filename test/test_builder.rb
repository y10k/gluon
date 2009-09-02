#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'gluon'
require 'test/unit'

module Gluon::Test
  class BuilderTest < Test::Unit::TestCase
    def setup
      @base_dir = File.dirname(__FILE__)
      @lib_dir = File.join(@base_dir, 'lib')
      @view_dir = File.join(@base_dir, 'view')
      @config_rb = File.join(@base_dir, 'config.rb')
      @builder = Gluon::Builder.new(@base_dir)
    end

    def test_attributes
      assert_equal(@base_dir, @builder.base_dir)
      assert_equal(@lib_dir, @builder.lib_dir)
      assert_equal(@view_dir, @builder.view_dir)
      assert_equal(@config_rb, @builder.config_rb)
    end

    def test_DSL_attributes_base_dir
      assert_equal(@base_dir, @builder.eval_conf('base_dir'))
    end

    def test_DSL_attributes_lib_dir
      assert_equal(@lib_dir, @builder.eval_conf('lib_dir'))
    end

    def test_DSL_attributes_view_dir
      assert_equal(@view_dir, @builder.eval_conf('view_dir'))
    end

    def test_DSL_attributes_config_rb
      assert_equal(@config_rb, @builder.eval_conf('config_rb'))
    end

    class Foo
      include Gluon::Controller
    end

    def test_to_app
      @builder.eval_conf %Q{
        map '/' do |entry|
          entry.mount #{Foo}
        end
      }
      app = @builder.to_app
      assert_instance_of(Gluon::Root, app)
      assert_instance_of(Rack::URLMap, app.inner)
    end

    def test_use
      @builder.eval_conf %Q{
        use Rack::ShowExceptions
        map '/' do |entry|
          entry.mount #{Foo}
        end
      }
      app = @builder.to_app
      assert_instance_of(Gluon::Root, app)
      assert_instance_of(Rack::ShowExceptions, app.inner)
    end

    def test_mount_use
      @builder.eval_conf %Q{
        map '/' do |entry|
          entry.use Rack::ShowExceptions
          entry.mount #{Foo}
        end
      }
      # no way to prove internal application.
    end

    def test_mount_run
      @builder.eval_conf %Q{
        map '/' do |entry|
          entry.run Rack::Directory.new('.')
        end
      }
      # no way to prove internal application.
    end

    class Bar
      class << self
        attr_accessor :new_count
        attr_accessor :final_count
      end
      self.new_count = 0
      self.final_count = 0

      def initialize
        self.class.new_count += 1
      end

      def finalize
        self.class.final_count += 1
      end
    end

    def test_backend_service_start_stop
      new_count = Bar.new_count
      final_count = Bar.final_count

      @builder.eval_conf %Q{
        backend_service :bar do |service|
          service.start do
            #{Bar}.new
          end
          service.stop do |bar|
            bar.finalize
          end
        end
      }

      assert_equal(new_count, Bar.new_count)
      assert_equal(final_count, Bar.final_count)

      @builder.to_app

      assert_equal(new_count + 1, Bar.new_count)
      assert_equal(final_count, Bar.final_count)

      @builder.shutdown

      assert_equal(new_count + 1, Bar.new_count)
      assert_equal(final_count + 1, Bar.final_count)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
