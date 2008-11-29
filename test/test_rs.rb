#!/usr/local/bin/ruby

require 'digest'
require 'gluon'
require 'rack'
require 'store_test_helper'
require 'test/unit'

module Gluon::Test
  class MemoryStoreTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    include SessionStoreTestHelper

    def setup
      @store = Gluon::MemoryStore.new(:expire_interval => 0)
    end

    def teardown
      @store.close
    end
  end

  class SessionManagerTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    def setup
      @store = Gluon::MemoryStore.new(:expire_interval => 0)
      @man = Gluon::SessionManager.new(:store => @store)
      @req = Rack::Request.new({})
      @res = Rack::Response.new
    end

    def test_new_session
      id = nil
      @man.transaction(@req, @res) {|handler|
        session = handler.get   # create
        id = handler.id
        assert_equal({}, session)
        session['foo'] = "Hello world.\n"
        assert_equal(session, handler.get) # get
      }
      assert_match(/session_id=#{Regexp.quote(id)}/, @res['Set-Cookie'])
      assert_equal({ 'foo' => "Hello world.\n" }, Marshal.load(@store.load(id)))
    end

    def test_new_session2
      foo_id = nil
      bar_id = nil

      @man.transaction(@req, @res) {|handler|
        handler.get(true, :key => 'foo')
        foo_id = handler.id('foo')

        handler.get(true, :key => 'bar')
        bar_id = handler.id('bar')
      }

      foo_cookie = @res['Set-Cookie'].find{|c| c =~ /foo=#{Regexp.quote(foo_id)}/ } or flunk('not found a session key')
      assert_equal({}, Marshal.load(@store.load(foo_id)))

      bar_cookie = @res['Set-Cookie'].find{|c| c =~ /bar=#{Regexp.quote(bar_id)}/ } or flunk('not found a session key')
      assert_equal({}, Marshal.load(@store.load(bar_id)))
    end

    def test_session_continue
      id = nil
      @man.transaction(@req, @res) {|handler|
        session = handler.get
        id = handler.id
        session['foo'] = "Hello world.\n"
      }

      /session_id=#{Regexp.quote(id)}/ =~ @res['Set-Cookie'] or flunk('not found a session id')
      req2 = Rack::Request.new({ 'HTTP_COOKIE' => "session_id=#{id}" })
      res2 = Rack::Response.new

      @man.transaction(req2, res2) {|handler|
        assert_equal(id, handler.id)
        session = handler.get
        assert_equal({ 'foo' => "Hello world.\n" }, session)
      }
    end

    def test_session_rollback
      # create a cookie for session
      id = nil
      @man.transaction(@req, @res) {|handler|
        handler.get
        id = handler.id
      }
      assert_match(/session_id=#{Regexp.quote(id)}/, @res['Set-Cookie'])

      req2 = Rack::Request.new({ 'HTTP_COOKIE' => "session_id=#{id}" })
      res2 = Rack::Response.new

      begin
        @man.transaction(req2, res2) {|handler|
          session = handler.get
          assert_equal(id, handler.id)
          session['foo'] = "Hello world.\n"
          raise RuntimeError
        }
        flunk('not to reach')
      rescue RuntimeError
        # nothing to do.
      end
      assert_equal({}, Marshal.load(@store.load(id)))
    end

    def test_session_expired
      id = nil
      @man.transaction(@req, @res) {|handler|
        session = handler.get
        id = handler.id
        session['foo'] = "Hello world.\n"
      }

      /session_id=#{Regexp.quote(id)}/ =~ @res['Set-Cookie'] or flunk('not found a session id')
      req2 = Rack::Request.new({ 'HTTP_COOKIE' => "session_id=#{id}" })
      res2 = Rack::Response.new
      @store.delete(id)         # expire session

      @man.transaction(req2, res2) {|handler|
        assert_nil(handler.id)
        assert_nil(handler.get(false))
      }
    end

    def test_session_expired_and_create
      id = nil
      @man.transaction(@req, @res) {|handler|
        session = handler.get
        id = handler.id
        session['foo'] = "Hello world.\n"
      }

      /session_id=#{Regexp.quote(id)}/ =~ @res['Set-Cookie'] or flunk('not found a session id')
      req2 = Rack::Request.new({ 'HTTP_COOKIE' => "session_id=#{id}" })
      res2 = Rack::Response.new
      @store.delete(id)         # expire session

      id2 = nil
      @man.transaction(req2, res2) {|handler|
        assert_nil(handler.id)
        assert_equal({}, handler.get)
        assert_not_equal(id, handler.id)
      }
    end

    def test_session_not_found
      @man.transaction(@req, @res) {|handler|
        assert_nil(handler.get(false))
        assert_nil(handler.id)
        assert_nil(handler.delete)
      }
    end

    def test_session_with_options
      @man.transaction(@req, @res) {|handler|
        handler.get(true, :domain => 'www.foo.net', :path => '/')
      }
      assert_match(%r"session_id=\S+; domain=www.foo.net; path=/", @res['Set-Cookie'])
    end

    def test_delete
      id = nil
      @man.transaction(@req, @res) {|handler|
        handler.get
        id = handler.id
        assert_equal({}, handler.delete)
      }

      assert_nil(@res['Set-Cookie'])
      assert_nil(@store.load(id))
    end

    def test_delete2
      id = nil
      @man.transaction(@req, @res) {|handler|
        session = handler.get
        id = handler.id
        session['foo'] = "Hello world.\n"
      }
      assert_match(/session_id=#{Regexp.quote(id)}/, @res['Set-Cookie'])
      assert_equal({ 'foo' => "Hello world.\n" }, Marshal.load(@store.load(id)))

      req2 = Rack::Request.new({ 'HTTP_COOKIE' => "session_id=#{id}" })
      res2 = Rack::Response.new

      @man.transaction(req2, res2) {|handler|
        assert_equal({ 'foo' => "Hello world.\n" }, handler.get)
        assert_equal(id, handler.id)
        assert_equal({ 'foo' => "Hello world.\n" }, handler.delete)
      }
      assert_nil(res2['Set-Cookie'])
      assert_nil(@store.load(id))
    end

    def test_delete3
      id = nil
      @man.transaction(@req, @res) {|handler|
        session = handler.get
        id = handler.id
        session['foo'] = "Hello world.\n"
      }
      assert_match(/session_id=#{Regexp.quote(id)}/, @res['Set-Cookie'])
      assert_equal({ 'foo' => "Hello world.\n" }, Marshal.load(@store.load(id)))

      req2 = Rack::Request.new({ 'HTTP_COOKIE' => "session_id=#{id}" })
      res2 = Rack::Response.new

      @man.transaction(req2, res2) {|handler|
        assert_equal({ 'foo' => "Hello world.\n" }, handler.delete)
        assert_nil(handler.get(false))
      }
      assert_nil(res2['Set-Cookie'])
      assert_nil(@store.load(id))
    end

    def test_auto_expire
      time_to_live = 0.01
      @man = Gluon::SessionManager.new(:store => @store, :time_to_live => time_to_live)
      assert_equal(true, @man.auto_expire?)
      assert_equal(time_to_live, @man.time_to_live)

      @man.transaction(@req, @res) {|handler|
        handler.get(true, :key => 'foo')
      }
      /foo=(\S*)/ =~ @res['Set-Cookie'] && id = $1 or flunk('not found a session id')

      sleep(time_to_live * 1.5)

      @man.transaction(@req, @res) {|handler|
        handler.get(true, :key => 'bar')
      }

      assert_nil(@store.load(id))
    end

    def test_default_settings
      @man = Gluon::SessionManager.new(:default_key => 'foo',
                                       :default_domain => 'www.foo.net',
                                       :default_path => '/foo',
                                       :id_max_length => 100,
                                       :time_to_live => 60 * 30,
                                       :auto_expire => false,
                                       :digest => Digest::SHA512,
                                       :store => @store)

      assert_equal('foo', @man.default_key)
      assert_equal('www.foo.net', @man.default_domain)
      assert_equal('/foo', @man.default_path)
      assert_equal(100, @man.id_max_length)
      assert_equal(60 * 30, @man.time_to_live)
      assert_equal(false, @man.auto_expire?)

      @man.transaction(@req, @res) {|handler|
        session = handler.get
        session['foo'] = "Hello world.\n"
      }

      assert_match(/foo=\S*;/, @res['Set-Cookie'])
      assert_match(/; domain=www\.foo\.net/, @res['Set-Cookie'])
      assert_match(%r"; path=/foo", @res['Set-Cookie'])

      /foo=(\S*);/ =~ @res['Set-Cookie'] && id = $1 or flunk('not found a session id')
      assert_equal(100, id.length, "id: #{id}")
      assert_equal({ 'foo' => "Hello world.\n" }, Marshal.load(@store.load(id)))
    end
  end

  class RequestResponseContextTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    class Foo
    end

    class Bar
    end

    def setup
      @env = Rack::MockRequest.env_for('http://foo:8080/bar.cgi',
                                       'SCRIPT_NAME' => '/bar.cgi')
      @req = Rack::Request.new(@env)
      @res = Rack::Response.new
      @session = Object.new     # dummy
      @url_map = Gluon::URLMap.new
      @url_map.mount(Foo, '/foo')
      @url_map.setup
      @renderer = Gluon::ViewRenderer.new(Dir.getwd)
      @c = Gluon::RequestResponseContext.new(@req, @res, @session, @url_map, @renderer)
    end

    def test_req_res
      assert_equal(@req, @c.req)
      assert_equal(@res, @c.res)
    end

    def test_lookup
      assert_equal(nil, @c.lookup('/'))
      assert_equal([ Foo, nil, [] ], @c.lookup('/foo'))
      assert_equal(nil, @c.lookup('/foo/'))
      assert_equal(nil, @c.lookup('/foo/bar'))
    end

    def test_class2path
      assert_equal('/bar.cgi/foo', @c.class2path(Foo))
      assert_equal(nil, @c.class2path(Bar))
    end

    def test_version
      @env['gluon.version'] = '0.0.0'
      assert_equal('0.0.0', @c.version)
    end

    def test_curr_page
      @env['gluon.curr_page'] = Foo
      assert_equal(Foo, @c.curr_page)
    end

    def test_path_info
      @env['gluon.path_info'] = '/bar'
      assert_equal('/bar', @c.path_info)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
