#!/usr/local/bin/ruby

require 'digest'
require 'gluon'
require 'rack'
require 'test/unit'

module Gluon::Test
  class MemoryStoreTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    def setup
      @store = Gluon::MemoryStore.new
    end

    def test_save_and_load
      assert_nil(@store.load('foo'))
      @store.save('foo', "Hello world.\n")
      assert_equal("Hello world.\n", @store.load('foo'))
    end

    def test_delete
      @store.save('foo', "Hello world.\n")
      @store.delete('foo')
      assert_nil(@store.load('foo'))
    end

    def test_not_delete_other_session
      @store.save('foo', "Hello world.\n")
      @store.delete('bar')
      assert_equal("Hello world.\n", @store.load('foo'))
    end

    def test_new_id
      assert_equal('foo', @store.new_id{ 'foo' })
    end

    def test_new_id_search
      @store.save('foo', '')
      @store.save('bar', '')
      id_list = %w[ foo bar baz ]
      assert_equal('baz', @store.new_id{ id_list.shift || flunk })
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

  class SessionManagerTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    def setup
      @store = Gluon::MemoryStore.new
      @man = Gluon::SessionManager.new(:store => @store)
      @req = Rack::Request.new({})
      @res = Rack::Response.new
    end

    def test_new_session
      @man.transaction(@req, @res) {|handler|
        session = handler.get
        assert_equal({}, session)
        session['foo'] = "Hello world.\n"
      }
      assert_match(/session_id=\S*/, @res['Set-Cookie'])
      /session_id=(\S*)/ =~ @res['Set-Cookie'] && id = $1 or flunk('not found a session id')
      assert_equal({ 'foo' => "Hello world.\n" }, Marshal.load(@store.load(id)))
    end

    def test_new_session2
      @man.transaction(@req, @res) {|handler|
        handler.get(true, :key => 'foo')
        handler.get(true, :key => 'bar')
      }

      foo_cookie = @res['Set-Cookie'].find{|c| c =~ /foo/ } or flunk('not found a session key')
      /foo=(\S*)/ =~ foo_cookie && foo_id = $1 or flunk('not found a session id')
      assert_equal({}, Marshal.load(@store.load(foo_id)))

      bar_cookie = @res['Set-Cookie'].find{|c| c =~ /bar/ } or flunk('not found a session key')
      /bar=(\S*)/ =~ bar_cookie && bar_id = $1 or flunk('not found a session id')
      assert_equal({}, Marshal.load(@store.load(bar_id)))
    end

    def test_session_rollback
      # create a cookie for session
      @man.transaction(@req, @res) {|handler|
        handler.get
      }
      assert_match(/session_id=\S*/, @res['Set-Cookie'])
      /session_id=(\S*)/ =~ @res['Set-Cookie'] && id = $1 or flunk('not found a session id')

      begin
        @man.transaction(@req, @res) {|handler|
          session = handler.get
          session['foo'] = "Hello world.\n"
          raise RuntimeError
        }
        flunk('not to reach')
      rescue RuntimeError
        # nothing to do.
      end

      assert_equal({}, Marshal.load(@store.load(id)))
    end

    def test_session_continue
      @man.transaction(@req, @res) {|handler|
        session = handler.get
        session['foo'] = "Hello world.\n"
      }

      /session_id=\S*/ =~ @res['Set-Cookie'] or flunk('not found a session id')
      req2 = Rack::Request.new({ 'HTTP_COOKIE' => $& })
      res2 = Rack::Response.new

      @man.transaction(req2, res2) {|handler|
        session = handler.get
        assert_equal({ 'foo' => "Hello world.\n" }, session)
      }
    end

    def test_session_not_found
      @man.transaction(@req, @res) {|handler|
        assert_raise(Gluon::SessionNotFoundError) {
          handler.get(false)
        }
      }
    end

    def test_session_with_options
      @man.transaction(@req, @res) {|handler|
        handler.get(true, :domain => 'www.foo.net', :path => '/')
      }
      assert_match(%r"session_id=\S+; domain=www.foo.net; path=/", @res['Set-Cookie'])
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
      @dispatcher = Gluon::Dispatcher.new([ [ '/foo', Foo ] ])
      @c = Gluon::RequestResponseContext.new(@req, @res, @session, @dispatcher)
    end

    def test_req_res
      assert_equal(@req, @c.req)
      assert_equal(@res, @c.res)
    end

    def test_look_up
      assert_equal(nil,             @c.look_up('/'))
      assert_equal([ Foo, '' ],     @c.look_up('/foo'))
      assert_equal([ Foo, '/' ],    @c.look_up('/foo/'))
      assert_equal([ Foo, '/bar' ], @c.look_up('/foo/bar'))
    end

    def test_class2path
      assert_equal('/foo', @c.class2path(Foo))
      assert_equal(nil,    @c.class2path(Bar))
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
