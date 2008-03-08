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
      @lib_dir = 'lib'
      FileUtils.rm_rf(@lib_dir) # for debug

      @view_dir = 'view'
      FileUtils.rm_rf(@view_dir) # for debug
      @renderer = Gluon::ViewRenderer.new(@view_dir)

      @env = Rack::MockRequest.env_for('http://foo:8080/bar.cgi')
      @env['SCRIPT_NAME'] = '/bar.cgi'
      @env['PATH_INFO'] = ''
      @mock = Gluon::Mock.new
      @c = @mock.new_request(@env)
    end

    def teardown
      FileUtils.rm_rf(@lib_dir) unless $DEBUG
      FileUtils.rm_rf(@view_dir) unless $DEBUG
    end

    def build_page(page_type)
      @page = page_type.new
      @action = Gluon::Action.new(@page, @c)
      @po = Gluon::PresentationObject.new(@page, @c, @renderer, @action)
      @erb_context = Gluon::ERBContext.new(@po, @c)
    end
    private :build_page

    def make_file(filename)
      FileUtils.mkdir_p(File.dirname(filename))
      File.open(filename, 'w') {|out|
        yield(out)
      }
    end
    private :make_file

    class PageForImplicitView
    end

    def test_view_implicit
      make_file("#{@view_dir}/Gluon/Test/ViewRendererTest/PageForImplicitView.rhtml") {|out|
        out << "Hello world.\n"
      }
      build_page(PageForImplicitView)
      assert_equal("Hello world.\n", @renderer.render(@erb_context))
    end

    def test_view_implicit_not_exist
      build_page(PageForImplicitView)
      assert_raise(RuntimeError) {
        @renderer.render(@erb_context)
      }
    end

    class PageForExplicitView
      def __view__
        'Foo.rhtml'
      end
    end

    def test_view_explicit
      make_file("#{@view_dir}/Foo.rhtml") {|out|
        out << "Hello world.\n"
      }
      build_page(PageForExplicitView)
      assert_equal("Hello world.\n", @renderer.render(@erb_context))
    end

    def test_view_explicit_not_exist
      build_page(PageForExplicitView)
      begin
        @renderer.render(@erb_context)
        flunk('not to reach')
      rescue
        assert_instance_of(Errno::ENOENT, $!)
        assert_match(Regexp.compile(Regexp.quote("#{@view_dir}/Foo.rhtml")), $!.to_s)
        return
      end
      flunk('not to reach')
    end

    def test_default_view
      page_path         = "#{@lib_dir}/Gluon/Test/ViewRendererTest/PageForDefaultView.rb"
      default_view_path = "#{@lib_dir}/Gluon/Test/ViewRendererTest/PageForDefaultView.rhtml"

      make_file(page_path) {|out|
        out.write <<-'EOF'
          module Gluon
            module Test
              class ViewRendererTest
                class PageForDefaultView
                  def __default_view__
                    dir = File.dirname(__FILE__)
                    name = File.basename(__FILE__, '.rb')
                    File.join(dir, name + '.rhtml')
                  end
                end
              end
            end
          end
        EOF
      }

      make_file(default_view_path) {|out|
        out << "Hello world.\n"
      }

      load(page_path)
      build_page(PageForDefaultView)
      assert_equal("Hello world.\n", @renderer.render(@erb_context))
    end

    def test_default_view_not_exist
      page_path         = "#{@lib_dir}/Gluon/Test/ViewRendererTest/PageForDefaultViewNotExist.rb"
      default_view_path = "#{@lib_dir}/Gluon/Test/ViewRendererTest/PageForDefaultViewNotExist.rhtml"

      make_file(page_path) {|out|
        out.write <<-'EOF'
          module Gluon
            module Test
              class ViewRendererTest
                class PageForDefaultViewNotExist
                  def __default_view__
                    dir = File.dirname(__FILE__)
                    name = File.basename(__FILE__, '.rb')
                    File.join(dir, name + '.rhtml')
                  end
                end
              end
            end
          end
        EOF
      }

      load(page_path)
      build_page(PageForDefaultViewNotExist)
      begin
        @renderer.render(@erb_context)
        flunk('not to reach')
      rescue
        assert_instance_of(Errno::ENOENT, $!)
        assert_match(Regexp.compile(Regexp.quote(default_view_path)), $!.to_s)
        return
      end
      flunk('not to reach')
    end

    def test_view_implicit_override_default
      page_path         = "#{@lib_dir}/Gluon/Test/ViewRendererTest/PageForViewImplicitOverrideDefault.rb"
      default_view_path = "#{@lib_dir}/Gluon/Test/ViewRendererTest/PageForViewImplicitOverrideDefault.rhtml"
      view_path         = "#{@view_dir}/Gluon/Test/ViewRendererTest/PageForViewImplicitOverrideDefault.rhtml"

      make_file(page_path) {|out|
        out.write <<-'EOF'
          module Gluon
            module Test
              class ViewRendererTest
                class PageForViewImplicitOverrideDefault
                  def __default_view__
                    dir = File.dirname(__FILE__)
                    name = File.basename(__FILE__, '.rb')
                    File.join(dir, name + '.rhtml')
                  end
                end
              end
            end
          end
        EOF
      }

      make_file(default_view_path) {|out|
        out << 'foo'
      }

      make_file(view_path) {|out|
        out << 'bar'
      }

      load(page_path)
      build_page(PageForViewImplicitOverrideDefault)
      assert_equal('bar', @renderer.render(@erb_context))
    end

    def test_view_explicit_override_default
      page_path         = "#{@lib_dir}/Gluon/Test/ViewRendererTest/PageForViewExplicitOverrideDefault.rb"
      default_view_path = "#{@lib_dir}/Gluon/Test/ViewRendererTest/PageForViewExplicitOverrideDefault.rhtml"
      view_path         = "#{@view_dir}/Foo.rhtml"

      make_file(page_path) {|out|
        out.write <<-'EOF'
          module Gluon
            module Test
              class ViewRendererTest
                class PageForViewExplicitOverrideDefault
                  def __default_view__
                    dir = File.dirname(__FILE__)
                    name = File.basename(__FILE__, '.rb')
                    File.join(dir, name + '.rhtml')
                  end

                  def __view__
                    'Foo.rhtml'
                  end
                end
              end
            end
          end
        EOF
      }

      make_file(default_view_path) {|out|
        out << 'foo'
      }

      make_file(view_path) {|out|
        out << 'bar'
      }

      load(page_path)
      build_page(PageForViewExplicitOverrideDefault)
      assert_equal('bar', @renderer.render(@erb_context))
    end

    def test_view_explicit_not_exist_override_default
      page_path         = "#{@lib_dir}/Gluon/Test/ViewRendererTest/PageForViewExplicitNotExistOverrideDefault.rb"
      default_view_path = "#{@lib_dir}/Gluon/Test/ViewRendererTest/PageForViewExplicitNotExistOverrideDefault.rhtml"
      view_path         = "#{@view_dir}/Foo.rhtml"

      make_file(page_path) {|out|
        out.write <<-'EOF'
          module Gluon
            module Test
              class ViewRendererTest
                class PageForViewExplicitNotExistOverrideDefault
                  def __default_view__
                    dir = File.dirname(__FILE__)
                    name = File.basename(__FILE__, '.rb')
                    File.join(dir, name + '.rhtml')
                  end

                  def __view__
                    'Foo.rhtml'
                  end
                end
              end
            end
          end
        EOF
      }

      make_file(default_view_path) {|out|
        out << 'foo'
      }

      load(page_path)
      build_page(PageForViewExplicitNotExistOverrideDefault)
      begin
        @renderer.render(@erb_context)
        flunk('not to reach')
      rescue
        assert_instance_of(Errno::ENOENT, $!)
        assert_match(Regexp.compile(Regexp.quote(view_path)), $!.to_s)
        return
      end
      flunk('not to reach')
    end

    class NoMethodPage
    end

    def test_view_explicit
      make_file("#{@view_dir}/Foo.rhtml") {|out|
        out << "<%= value :foo %>"
      }

      build_page(PageForExplicitView)
      assert_raise(NoMethodError) {
        @renderer.render(@erb_context)
      }
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
