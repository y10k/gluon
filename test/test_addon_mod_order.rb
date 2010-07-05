#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'gluon'
require 'test/unit'

module Gluon::Test
  class AddOnModuleOrderTest < Test::Unit::TestCase
    class C_super
      def initialize
        @addon_around_call = []
        @addon_init_call = []
        @addon_final_call = []
      end

      attr_reader :addon_around_call
      attr_reader :addon_init_call
      attr_reader :addon_final_call

      def __addon_around__
        @addon_around_call << [ C_super, :start ]
        r = yield
        @addon_around_call << [ C_super, :end ]
        r
      end

      def __addon_init__
        @addon_init_call << C_super
      end

      def __addon_final__
        @addon_final_call << C_super
      end
    end

    module M_super
      def __addon_around__
        r = nil
        super{                  # super for add-on chain.
          @addon_around_call << [ M_super, :start ]
          r = yield
          @addon_around_call << [ M_super, :end ]
        }

        r
      end

      def __addon_init__
        super                   # for add-on chain.
        @addon_init_call << M_super
      end

      def __addon_final__
        @addon_final_call << M_super
        super                   # for add-on chain.
      end
    end

    module M_a
      include M_super

      def __addon_around__
        r = nil
        super{                  # super for add-on chain.
          @addon_around_call << [ M_a, :start ]
          r = yield
          @addon_around_call << [ M_a, :end ]
        }

        r
      end

      def __addon_init__
        super                   # for add-on chain.
        @addon_init_call << M_a
      end

      def __addon_final__
        @addon_final_call << M_a
        super                   # for add-on chain.
      end
    end

    module M_b
      include M_super

      def __addon_around__
        r = nil
        super{                  # for add-on chain.
          @addon_around_call << [ M_b, :start ]
          r = yield
          @addon_around_call << [ M_b, :end ]
        }

        r
      end

      def __addon_init__
        super                   # for add-on chain.
        @addon_init_call << M_b
      end

      def __addon_final__
        @addon_final_call << M_b
        super                   # for add-on chain.
      end
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

    def test_addon_around_call
      c = C.new
      r = c.__addon_around__{
        'Hello world.'
      }
      assert_equal('Hello world.', r)
      assert_equal([ [ C_super, :start ],
                     [ M_super, :start ],
                     [ M_a, :start ],
                     [ M_b, :start ],
                     [ M_b, :end ],
                     [ M_a, :end ],
                     [ M_super, :end ],
                     [ C_super, :end ]
                   ], c.addon_around_call)
                     
    end

    def test_addon_init_call
      c = C.new
      c.__addon_init__
      assert_equal([ C_super,
                     M_super,
                     M_a,
                     M_b
                   ], c.addon_init_call)
    end

    def test_addon_final_call
      c = C.new
      c.__addon_final__
      assert_equal([ M_b,
                     M_a,
                     M_super,
                     C_super
                   ], c.addon_final_call)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
