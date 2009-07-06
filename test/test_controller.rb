#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'gluon'
require 'test/unit'

module Gluon::Test
  class ControllerTest < Test::Unit::TestCase
    def setup
      @c = Class.new
      @c.class_eval{
        include Gluon::Controller
      }
    end

    def test_gluon_path_filter
      @c.class_eval{ gluon_path_filter %r"^/foo/([^/]+)$" }
      assert_equal(%r"^/foo/([^/]+)$",
                   Gluon::Controller.find_path_filter(@c))
    end

    def test_gluon_path_filter_not_inherited
      subclass = Class.new(@c)
      assert_nil(Gluon::Controller.find_path_filter(subclass))
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
