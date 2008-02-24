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

    class SessionCountPage
      attr_accessor :c

      def page_start
	session = @c.session_get
	session[:count] = 0 unless (session.key? :count)
	session[:count] += 1
      end
    end

    def test_session_uninitialized
      assert((@mock.respond_to? :session_get))
      assert_raise(NoMethodError) {
	@mock.session_get
      }
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
      assert_match(/session_id=\S*/, c.res['Set-Cookie'])
      c = @mock.new_request(env)

      count = SessionCountPage.new
      count.c = c
      count.page_start

      assert_equal({ :count => 1 }, @mock.session_get)
      @mock.close_response
      assert_match(/session_id=\S*/, c.res['Set-Cookie'])
    end
  end
end
