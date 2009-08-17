#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'gluon'
require 'test/unit'

module Gluon::Test
  class BackendServiceManagerTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    def setup
      @service_man = Gluon::BackendServiceManager.new
    end

    class Foo
    end

    class FooServiceAdaptor
      include Gluon::BackendServiceAdaptor

      def gluon_service_key
        :foo
      end

      def gluon_service_get
        Foo.new
      end
    end

    class Bar
      attr_accessor :around_hook_start
      attr_accessor :around_hook_end
      attr_accessor :start
      attr_accessor :end
    end

    class BarServiceAdaptor
      include Gluon::BackendServiceAdaptor

      def initialize
        @bar = Bar.new
        @count = 0
      end

      def count_up
        c = @count
        @count += 1
        c
      end
      private :count_up

      def gluon_service_key
        :bar
      end

      def gluon_service_around_hook
        @bar.around_hook_start = count_up
        begin
          yield
        ensure
          @bar.around_hook_end = count_up
        end
      end

      def gluon_service_start
        @bar.start = count_up
      end

      def gluon_service_get
        @bar
      end

      def gluon_service_end
        @bar.end = count_up
      end
    end

    def test_new_services
      count = 0
      bar = nil

      @service_man.register(FooServiceAdaptor.new)
      @service_man.register(BarServiceAdaptor.new)
      @service_man.apply_around_hook{
        @service_man.setup
        bs = @service_man.new_services

        assert_instance_of(Foo, bs.foo)
        assert_instance_of(Foo, bs[:foo])
        assert_instance_of(Bar, bs.bar)
        assert_instance_of(Bar, bs[:bar])

        assert_equal(0, bs.bar.around_hook_start)
        assert_equal(1, bs.bar.start)
        assert_equal(nil, bs.bar.end)
        assert_equal(nil, bs.bar.around_hook_end)

        @service_man.shutdown

        count += 1
        bar = bs.bar
      }

      assert_equal(1, count)

      assert_equal(0, bar.around_hook_start)
      assert_equal(1, bar.start)
      assert_equal(2, bar.end)
      assert_equal(3, bar.around_hook_end)
    end

    def test_no_services
      count = 0
      @service_man.apply_around_hook{
        @service_man.setup
        bs = @service_man.new_services
        assert_raise(NoMethodError) { bs.foo }
        assert_raise(NameError) { bs[:foo] }
        @service_man.shutdown
        count += 1
      }
      assert_equal(1, count)
    end

    FROZEN_ERROR = case (RUBY_VERSION)
                   when /^1\.8\./
                     TypeError
                   when /^1\.9\./
                     RuntimeError
                   else
                     raise "unkonwn ruby version: #{RUBY_VERSION}"
                   end

    def test_freeze
      count = 0
      @service_man.apply_around_hook{
        @service_man.setup
        assert_raise(FROZEN_ERROR) {
          @service_man.register(FooServiceAdaptor.new)
        }
        count += 1
      }
      assert_equal(1, count)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
