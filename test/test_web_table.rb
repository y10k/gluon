#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'gluon'
require 'test/unit'

module Gluon::Test
  class WebTableTest < Test::Unit::TestCase
    def test_each_row
      rows = Gluon::Web::Table.each_row(3,
                                        [ 1, 2, 3,
                                          4, 5, 6,
                                          7, 8, 9 ])

      assert_equal([ 1, 2, 3 ], rows.next)
      assert_equal([ 4, 5, 6 ], rows.next)
      assert_equal([ 7, 8, 9 ], rows.next)
      assert_raise(StopIteration) { rows.next }
    end

    def test_each_row_empty
      Gluon::Web::Table.each_row(3, []) do |row|
        flunk('not to reach.')
      end
    end

    def test_each_row_single
      rows = Gluon::Web::Table.each_row(3, [ 1, 2, 3 ])
      assert_equal([ 1, 2, 3 ], rows.next)
      assert_raise(StopIteration) { rows.next }
    end

    def test_each_row_not_filled
      rows = Gluon::Web::Table.each_row(3,
                                        [ 1, 2, 3,
                                          4, 5, 6,
                                          7, 8 ])

      assert_equal([ 1, 2, 3 ], rows.next)
      assert_equal([ 4, 5, 6 ], rows.next)
      assert_equal([ 7, 8 ], rows.next)
      assert_raise(StopIteration) { rows.next }
    end

    def test_build
      tbl = Gluon::Web::ForeachTable.build(3,
                                           [ 1, 2, 3,
                                             4, 5, 6,
                                             7, 8, 9 ])

      rows = tbl.each
      assert_equal([ 1, 2, 3 ], rows.next.cells)
      assert_equal([ 4, 5, 6 ], rows.next.cells)
      assert_equal([ 7, 8, 9 ], rows.next.cells)
      assert_raise(StopIteration) { rows.next }
    end

    def test_build_dsl
      tbl = Gluon::Web::ImportTable.build(3,
                                          %w[ A B C
                                              X 1 2
                                              Y 3 4 ]) do |tbl, rows|
        tbl.tr{|tr| rows.next.each{|v| tr.th(v) } }
        loop do
          r = rows.next
          tbl.tr{|tr| tr.th(r.shift); r.each{|v| tr.td(v) } }
        end
      end

      assert_equal(3, tbl.rows.length)

      assert_equal(3, tbl.rows[0].cells.length)
      assert(tbl.rows[0].cells[0].header?)
      assert_equal('A', tbl.rows[0].cells[0].item.value)
      assert(tbl.rows[0].cells[1].header?)
      assert_equal('B', tbl.rows[0].cells[1].item.value)
      assert(tbl.rows[0].cells[2].header?)
      assert_equal('C', tbl.rows[0].cells[2].item.value)

      assert_equal(3, tbl.rows[1].cells.length)
      assert(tbl.rows[1].cells[0].header?)
      assert_equal('X', tbl.rows[1].cells[0].item.value)
      assert(tbl.rows[1].cells[1].data?)
      assert_equal('1', tbl.rows[1].cells[1].item.value)
      assert(tbl.rows[1].cells[2].data?)
      assert_equal('2', tbl.rows[1].cells[2].item.value)

      assert_equal(3, tbl.rows[2].cells.length)
      assert(tbl.rows[2].cells[0].header?)
      assert_equal('Y', tbl.rows[2].cells[0].item.value)
      assert(tbl.rows[2].cells[1].data?)
      assert_equal('3', tbl.rows[2].cells[1].item.value)
      assert(tbl.rows[2].cells[2].data?)
      assert_equal('4', tbl.rows[2].cells[2].item.value)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
