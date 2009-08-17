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

    def test_no_service
      @service_man.setup
      svc = @service_man.new_services
      assert_equal([ :__no_service__ ], svc.members)
      assert_equal([ nil ], svc.values)
      @service_man.shutdown
    end

    class Foo
      def initialize
	@finalized = false
      end

      def finalized?
	@finalized
      end

      def finalize
	if (@finalized) then
	  raise 'duplicated finalize call.'
	end
	@finalized = true
	nil
      end
    end

    def test_service
      foo = Foo.new
      assert_equal(false, foo.finalized?)

      @service_man.add(:foo, foo) {|f|
	f.finalize
      }
      assert_equal(false, foo.finalized?)

      @service_man.setup
      assert_equal(false, foo.finalized?)

      svc = @service_man.new_services
      assert_equal(false, foo.finalized?)
      assert_equal([ :foo ], svc.members)
      assert_equal([ foo ], svc.values)
      assert_equal(foo, svc.foo)

      @service_man.shutdown
      assert_equal(true, foo.finalized?)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
