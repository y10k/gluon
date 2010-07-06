#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'gluon'
require 'test/unit'

module Gluon::Test
  class AddOnModuleOrderTest < Test::Unit::TestCase
    class C_super
    end

    module M_super
    end

    module M_a
      include M_super
    end

    module M_b
      include M_super
    end

    class C < C_super
      include M_a
      include M_b
    end
    
    def test_module_order
      order = {}
      C.ancestors.each_with_index do |m, i|
        order[m] = i
      end

      assert(order[C] < order[C_super])
      assert(order[C] < order[M_super])
      assert(order[C] < order[M_a])
      assert(order[C] < order[M_b])

      assert(order[M_b] < order[C_super])
      assert(order[M_b] < order[M_super])
      assert(order[M_b] < order[M_a])
      assert(order[M_b] > order[C])

      assert(order[M_a] < order[C_super])
      assert(order[M_a] < order[M_super])
      assert(order[M_a] > order[M_b])
      assert(order[M_a] > order[C])

      assert(order[M_super] < order[C_super])
      assert(order[M_super] > order[M_a])
      assert(order[M_super] > order[M_b])
      assert(order[M_super] > order[C])

      assert(order[C_super] > order[M_super])
      assert(order[C_super] > order[M_a])
      assert(order[C_super] > order[M_b])
      assert(order[C_super] > order[C])
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
