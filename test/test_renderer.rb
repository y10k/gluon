#!/usr/local/bin/ruby

require 'fileutils'
require 'gluon'
require 'rack'
require 'test/unit'

module Gluon::Test
  class ViewRendererTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    def setup
      @view_dir = 'view'
      FileUtils.rm_rf(@view_dir) # for debug
      FileUtils.mkdir_p(@view_dir)
      @renderer = Gluon::ViewRenderer.new(@view_dir)

      @env = Rack::MockRequest.env_for('http://foo:8080/bar.cgi')
      @env['SCRIPT_NAME'] = '/bar.cgi'
      @env['PATH_INFO'] = ''
      @req = Rack::Request.new(@env)
      @res = Rack::Response.new
      @session = Object.new     # dummy
      @dispatcher = Gluon::Dispatcher.new([])
      @c = Gluon::RequestResponseContext.new(@req, @res, @session, @dispatcher)
      @plugin = {}
    end

    def teardown
      FileUtils.rm_rf(@view_dir) unless $DEBUG
    end

    def build_page(page_type)
      @page = page_type.new
      @action = Gluon::Action.new(@page, @c, @plugin)
      @po = Gluon::PresentationObject.new(@page, @c, @renderer, @action)
      @erb_context = Gluon::ERBContext.new(@po, @c)
    end
    private :build_page

    def make_view(filename)
      FileUtils.mkdir_p(File.dirname(filename))
      File.open(filename, 'w') {|out|
        out.binmode
        yield(out)
      }
    end
    private :make_view

    class PageForImplicitView
    end

    def test_view_implicit
      make_view("#{@view_dir}/Gluon/Test/ViewRendererTest/PageForImplicitView.rhtml") {|out|
        out << "Hello world.\n"
      }
      build_page(PageForImplicitView)
      assert_equal("Hello world.\n", @renderer.render(@erb_context))
    end

    class PageForExplicitView
      def __view__
        'Foo.rhtml'
      end
    end

    def test_view_explicit
      make_view("#{@view_dir}/Foo.rhtml") {|out|
        out << "Hello world.\n"
      }
      build_page(PageForExplicitView)
      assert_equal("Hello world.\n", @renderer.render(@erb_context))
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
