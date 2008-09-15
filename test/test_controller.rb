#!/usr/local/bin/ruby

require 'gluon'
require 'test/unit'

module Gluon::Test
  class ControllerTest < Test::Unit::TestCase
    class Plain
    end

    class PathFilter
      gluon_path_filter %r"^/foo/([^/]+)$"
    end

    class PathFilterSubclass < PathFilter
    end

    def test_gluon_path_filter
      assert_equal(%r"^/foo/([^/]+)$",
                   Gluon::Controller.find_path_filter(PathFilter))
    end

    def test_gluon_path_filter_subclass
      assert_equal(%r"^/foo/([^/]+)$",
                   Gluon::Controller.find_path_filter(PathFilterSubclass))
    end

    def test_gluon_path_filter_not_defined
      assert_nil(Gluon::Controller.find_path_filter(Plain))
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

