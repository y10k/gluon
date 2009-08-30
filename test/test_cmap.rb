#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'gluon'
require 'test/unit'

module Gluon::Test
  class ClassMapTest < Test::Unit::TestCase
    def setup
      @cmap = Gluon::ClassMap.new
      @c = Class.new{ include Gluon::Controller }
    end

    def test_mount_root
      @cmap.mount(@c, '/')
      assert_equal('/', @cmap.class2path(@c))
    end

    def test_mount_root_no_path_args
      @cmap.mount(@c, '/')
      ex = assert_raise(ArgumentError) { @cmap.class2path(@c, 1975, 11, 19) }
      assert_equal('no need for path arguments.', ex.message)
    end

    def test_mount_root_path_block
      @c.class_eval{
        gluon_path_filter %r"^/(\d\d\d\d)-(\d\d)-(\d\d)$" do |year, mon, day|
          format("/%04d-%02d-%02d", year, mon, day)
        end
      }
      @cmap.mount(@c, '/')
      assert_equal('/1975-11-19', @cmap.class2path(@c, 1975, 11, 19))
    end

    def test_mount_root_path_block_no_slash
      @c.class_eval{
        gluon_path_filter %r"^/(\d\d\d\d)-(\d\d)-(\d\d)$" do |year, mon, day|
          format("%04d-%02d-%02d", year, mon, day)
        end
      }
      @cmap.mount(@c, '/')
      ex = assert_raise(RuntimeError) { @cmap.class2path(@c, 1975, 11, 19) }
      assert_match(/needs to start with slash: 1975-11-19$/, ex.message)
    end

    def test_mount_plain
      @cmap.mount(@c, '/foo')
      assert_equal('/foo', @cmap.class2path(@c))
    end

    def test_mount_plain_no_path_args
      @cmap.mount(@c, '/foo')
      ex = assert_raise(ArgumentError) { @cmap.class2path(@c, 1975, 11, 19) }
      assert_equal('no need for path arguments.', ex.message)
    end

    def test_mount_plain_path_block
      @c.class_eval{
        gluon_path_filter %r"^/(\d\d\d\d)-(\d\d)-(\d\d)$" do |year, mon, day|
          format("/%04d-%02d-%02d", year, mon, day)
        end
      }
      @cmap.mount(@c, '/foo')
      assert_equal('/foo/1975-11-19', @cmap.class2path(@c, 1975, 11, 19))
    end

    def test_mount_plain_path_block_no_slash
      @c.class_eval{
        gluon_path_filter %r"^/(\d\d\d\d)-(\d\d)-(\d\d)$" do |year, mon, day|
          format("%04d-%02d-%02d", year, mon, day)
        end
      }
      @cmap.mount(@c, '/foo')
      ex = assert_raise(RuntimeError) { @cmap.class2path(@c, 1975, 11, 19) }
      assert_match(/needs to start with slash: 1975-11-19$/, ex.message)
    end

    def test_mount_no_slash
      ex = assert_raise(ArgumentError) { @cmap.mount(@c, 'foo') }
      assert_equal('need to start with slash: foo', ex.message)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
