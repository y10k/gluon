#!/usr/local/bin/ruby

require 'digest'
require 'fileutils'
require 'gluon'
require 'test/unit'

module Gluon::Test
  class FileStoreTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    def setup
      @store_path = 'session'
      FileUtils.rm_rf(@store_path) if $DEBUG
      @store = Gluon::FileStore.new(@store_path, :expire_interval => 0)
    end

    def teardown
      FileUtils.rm_rf(@store_path) unless $DEBUG
    end

    def test_load_empty
      assert_nil(@store.load('foo'))
    end

    def test_load_empty2
      assert_nil(@store.load('foo'), 'FIRST')
      assert_nil(@store.load('foo'), 'SECOND')
    end

    def test_save_and_load
      assert_nil(@store.load('foo'))
      @store.save('foo', "Hello world.\n")
      assert_equal("Hello world.\n", @store.load('foo'))
    end

    def test_delete
      @store.save('foo', "Hello world.\n")
      assert_equal("Hello world.\n", @store.delete('foo'))
      assert_nil(@store.load('foo'))
    end

    def test_not_delete_other_session
      @store.save('foo', "Hello world.\n")
      assert_nil(@store.delete('bar'))
      assert_equal("Hello world.\n", @store.load('foo'))
    end

    def test_create
      assert_equal('foo', @store.create('bar') { 'foo' })
      assert_equal('bar', @store.load('foo'))
    end

    def test_create_empty
      assert_equal('foo', @store.create('') { 'foo' })
      assert_equal('', @store.load('foo'))
    end

    def test_create_and_search_new_id
      @store.save('foo', '')
      @store.save('bar', '')
      id_list = %w[ foo bar baz ]
      assert_equal('baz', @store.create('') { id_list.shift || flunk })
      assert_equal('', @store.load('baz'))
    end

    def test_expire
      now = Time.now
      @store.save('foo', "Hello world.\n")

      @store.expire(now - 1)
      assert_equal("Hello world.\n", @store.load('foo'))

      @store.expire(now + 1)
      assert_nil(@store.load('foo'))
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
