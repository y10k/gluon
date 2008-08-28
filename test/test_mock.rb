#!/usr/local/bin/ruby

require 'gluon'
require 'rack'
require 'test/unit'

module Gluon::Test
  class MockTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    def setup
      @mock = Gluon::Mock.new
      @req_uri = 'http://foo:8080/bar.cgi'
    end

    def test_session_uninitialized
      assert((@mock.respond_to? :session_get))
      assert_raise(NoMethodError) {
        @mock.session_get
      }
    end

    class SessionCountPage
      attr_writer :c

      def page_start
        session = @c.session_get
        session[:count] = 0 unless (session.key? :count)
        session[:count] += 1
      end
    end

    def test_mock_request_response
      env = Rack::MockRequest.env_for(@req_uri)
      c = @mock.new_request(env)
      assert_equal(nil, @mock.session_get)
      count = SessionCountPage.new
      count.c = c
      count.page_start
      assert_equal({ :count => 1 }, @mock.session_get)
      env = @mock.close_response(Rack::MockRequest.env_for(@req_uri))

      /session_id=\S*/ =~ c.res['Set-Cookie'] or flunk('not found a previous response cookie')
      prev_session_id = $&.split(/=/)[1]
      /session_id=\S*/ =~ env['HTTP_COOKIE'] or flunk('not found a next request cookie')
      next_session_id = $&.split(/=/)[1]
      assert(prev_session_id == next_session_id)

      c = @mock.new_request(env)
      count = SessionCountPage.new
      count.c = c
      count.page_start
      assert_equal({ :count => 2 }, @mock.session_get)
      env = @mock.close_response

      /session_id=\S*/ =~ env['HTTP_COOKIE'] or flunk('not found a next request cookie')
      next_session_id = $&.split(/=/)[1]
      /session_id=\S*/ =~ c.res['Set-Cookie'] or flunk('not found a previous response cookie')
      prev_session_id = $&.split(/=/)[1]
      assert(prev_session_id == next_session_id)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
