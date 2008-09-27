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
      @view_path = File.join(@view_dir, 'test_view' + Gluon::ERBView::SUFFIX)
      FileUtils.rm_rf(@view_dir) # for debug
      FileUtils.mkdir_p(@view_dir)
      @renderer = Gluon::ViewRenderer.new(@view_dir)

      @env = Rack::MockRequest.env_for('http://foo:8080/bar.cgi')
      @env['SCRIPT_NAME'] = '/bar.cgi'
      @env['PATH_INFO'] = ''
      @mock = Gluon::Mock.new
      @c = @mock.new_request(@env)
      @params, @funcs = Gluon::Action.parse(@c.req.params)
    end

    def teardown
      FileUtils.rm_rf(@view_dir) unless $DEBUG
    end

    def build_page(page_type)
      @controller = page_type.new
      @action = Gluon::Action.new(@controller, @c, @params, @funcs)
      @po = Gluon::PresentationObject.new(@controller, @c, @action)
    end
    private :build_page

    def make_view
      File.open(@view_path, 'w') {|out|
        yield(out)
      }
    end
    private :make_view

    class SimplePage
    end

    def test_view
      make_view{|out|
        out << "Hello world.\n"
      }
      build_page(SimplePage)
      assert_equal("Hello world.\n",
                   @renderer.render(Gluon::ERBView, @view_path, @c, @po))

      10.times do |i|
        build_page(SimplePage)
        assert_equal("Hello world.\n",
                     @renderer.render(Gluon::ERBView, @view_path, @c, @po))
      end
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
