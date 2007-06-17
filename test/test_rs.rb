#!/usr/local/bin/ruby

require 'gluon'
require 'rack'
require 'test/unit'

module Gluon::Test
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
      @dispatcher = Gluon::Dispatcher.new([ [ '/foo', Foo ] ])
      @c = Gluon::RequestResponseContext.new(@req, @res, @dispatcher)
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
