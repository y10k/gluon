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
      MockService.new_args = nil
      MockService.new_count = 0
      MockService.final_count = 0
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

    class MockController < Gluon::Controller
    end

    def test_to_app
      @builder.eval_conf %Q{
        map '/' do |entry|
          entry.mount #{MockController}
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
          entry.mount #{MockController}
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
          entry.mount #{MockController}
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

    module MockAddOn
      Config = Struct.new(:foo, :bar)

      def self.create_config
        Config.new('apple', 'banana')
      end
    end

    def test_config
      @builder.eval_conf %Q{
        config #{MockAddOn} do |conf|
          conf.foo = 'Orange'
        end
      }
      # no way to prove internal application.
    end

    class MockService
      class << self
        attr_accessor :new_args
        attr_accessor :new_count
        attr_accessor :final_count
      end

      def initialize(*args)
        self.class.new_args = args
        self.class.new_count += 1
      end

      def finalize
        self.class.final_count += 1
      end
    end

    def test_service_default
      @builder.eval_conf %Q{
        service #{MockService}
      }

      assert_equal(0, MockService.new_count)
      assert_equal(0, MockService.final_count)

      @builder.to_app

      assert_equal([], MockService.new_args)
      assert_equal(1, MockService.new_count)
      assert_equal(0, MockService.final_count)

      @builder.shutdown

      assert_equal(1, MockService.new_count)
      assert_equal(0, MockService.final_count)
    end

    def test_service_create
      @builder.eval_conf %Q{
        service #{MockService} do |svc|
          svc.create do |c|
            c.new('HALO')
          end
        end
      }

      assert_equal(0, MockService.new_count)
      assert_equal(0, MockService.final_count)

      @builder.to_app

      assert_equal([ 'HALO' ], MockService.new_args)
      assert_equal(1, MockService.new_count)
      assert_equal(0, MockService.final_count)

      @builder.shutdown

      assert_equal(1, MockService.new_count)
      assert_equal(0, MockService.final_count)
    end

    def test_service_destroy
      @builder.eval_conf %Q{
        service #{MockService} do |svc|
          svc.destroy do |o|
            o.finalize
          end
        end
      }

      assert_equal(0, MockService.new_count)
      assert_equal(0, MockService.final_count)

      @builder.to_app

      assert_equal([], MockService.new_args)
      assert_equal(1, MockService.new_count)
      assert_equal(0, MockService.final_count)

      @builder.shutdown

      assert_equal(1, MockService.new_count)
      assert_equal(1, MockService.final_count)
    end

    def test_service_create_destroy
      @builder.eval_conf %Q{
        service #{MockService} do |svc|
          svc.create do |c|
            c.new('HALO')
          end
          svc.destroy do |o|
            o.finalize
          end
        end
      }

      assert_equal(0, MockService.new_count)
      assert_equal(0, MockService.final_count)

      @builder.to_app

      assert_equal([ 'HALO' ], MockService.new_args)
      assert_equal(1, MockService.new_count)
      assert_equal(0, MockService.final_count)

      @builder.shutdown

      assert_equal(1, MockService.new_count)
      assert_equal(1, MockService.final_count)
    end

    def test_backend_service_start_stop
      new_count = MockService.new_count
      final_count = MockService.final_count

      @builder.eval_conf %Q{
        backend_service :bar do |service|
          service.start do
            #{MockService}.new
          end
          service.stop do |bar|
            bar.finalize
          end
        end
      }

      assert_equal(new_count, MockService.new_count)
      assert_equal(final_count, MockService.final_count)

      @builder.to_app

      assert_equal(new_count + 1, MockService.new_count)
      assert_equal(final_count, MockService.final_count)

      @builder.shutdown

      assert_equal(new_count + 1, MockService.new_count)
      assert_equal(final_count + 1, MockService.final_count)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
