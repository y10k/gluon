#!/usr/local/bin/ruby

require 'fileutils'
require 'gluon'
require 'rack'
require 'test/unit'

module Gluon::Test
  class CKViewParserTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    def test_parse_attrs
      assert_equal({ 'foo' => 'apple' },
                   Gluon::CKView.parse_attrs('foo="apple"'))
    end

    def test_parse_attrs_many
      assert_equal({ 'foo' => 'apple', 'bar' => 'banana' },
                   Gluon::CKView.parse_attrs('foo="apple" bar="banana"'))
    end

    def test_parse_attrs_sparsed
      assert_equal({ 'foo' => 'apple', 'bar' => 'banana' },
                   Gluon::CKView.parse_attrs(' foo =  "apple"  bar   = "banana" '))
    end

    def test_parse_attrs_densed
      assert_equal({ 'foo' => 'apple', 'bar' => 'banana' },
                   Gluon::CKView.parse_attrs('foo="apple"bar="banana"'))
    end

    def test_parse_attrs_single_quoted
      assert_equal({ 'foo' => 'apple' },
                   Gluon::CKView.parse_attrs("foo='apple'"))
    end

    def test_parse_attrs_quote_in_double_quoted
      assert_equal({ 'foo' => "'" },
                   Gluon::CKView.parse_attrs("foo=\"'\""))
    end

    def test_parse_attrs_quote_in_single_quoted
      assert_equal({ 'foo' => '"' },
                   Gluon::CKView.parse_attrs("foo='\"'"))
    end

    def test_parse_attrs_html_specials
      assert_equal({ 'foo' => '<', 'bar' => '>', 'baz' => '&', 'quux' => '"' },
                   Gluon::CKView.parse_attrs('foo="&lt;" bar="&gt;" baz="&amp;" quux="&quot;"'))
    end

    def test_parse_attrs_empty
      assert_equal({}, Gluon::CKView.parse_attrs(''))
    end

    def test_parse_text
      assert_equal([ [ :text, "Hello world.\n" ] ],
                   Gluon::CKView.parse("Hello world.\n"))
    end

    def test_parse_gluon_tag_single
      assert_equal([ [ :gluon_tag_single, '<gluon />', {} ] ],
                   Gluon::CKView.parse('<gluon />'))
    end

    def test_parse_gluon_tag_single_with_attrs
      assert_equal([ [ :gluon_tag_single,
                       '<gluon foo="Apple" bar="Banana" />',
                       { 'foo' => 'Apple', 'bar' => 'Banana' }
                     ]
                   ],
                   Gluon::CKView.parse('<gluon foo="Apple" bar="Banana" />'))
    end

    def test_parse_gluon_tag_single_sparsed
      assert_equal([ [ :gluon_tag_single,
                       "<\ngluon foo  =  'Apple'\tbar = 'Banana'\n/>",
                       { 'foo' => 'Apple', 'bar' => 'Banana' }
                     ]
                   ],
                   Gluon::CKView.parse("<\ngluon foo  =  'Apple'\tbar = 'Banana'\n/>"))
    end

    def test_parse_gluon_tag_single_densed
      assert_equal([ [ :gluon_tag_single,
                       '<gluon foo="Apple"bar="Banana"/>',
                       { 'foo' => 'Apple', 'bar' => 'Banana' }
                     ]
                   ],
                   Gluon::CKView.parse('<gluon foo="Apple"bar="Banana"/>'))
    end

    def test_parse_gluon_tag_start_end
      assert_equal([ [ :gluon_tag_start, '<gluon>', {} ],
                     [ :gluon_tag_end, '</gluon>' ]
                   ],
                   Gluon::CKView.parse('<gluon></gluon>'))
    end

    def test_parse_gluon_tag_start_end_with_attrs
      assert_equal([ [ :gluon_tag_start,
                       '<gluon foo="Apple" bar="Banana">',
                       { 'foo' => 'Apple', 'bar' => 'Banana' }
                     ],
                     [ :gluon_tag_end, '</gluon>' ]
                   ],
                   Gluon::CKView.parse('<gluon foo="Apple" bar="Banana"></gluon>'))
    end

    def test_parse_gluon_tag_start_end_sparsed
      assert_equal([ [ :gluon_tag_start,
                       "<\ngluon foo  =  'Apple'\tbar = 'Banana'\n>",
                       { 'foo' => 'Apple', 'bar' => 'Banana' }
                     ],
                     [ :gluon_tag_end, "</\n gluon  >" ]
                   ],
                   Gluon::CKView.parse("<\ngluon foo  =  'Apple'\tbar = 'Banana'\n></\n gluon  >"))
    end

    def test_parse_gluon_tag_start_end_densed
      assert_equal([ [ :gluon_tag_start,
                       '<gluon foo="Apple"bar="Banana">',
                       { 'foo' => 'Apple', 'bar' => 'Banana' }
                     ],
                     [ :gluon_tag_end, '</gluon>' ]
                   ],
                   Gluon::CKView.parse('<gluon foo="Apple"bar="Banana"></gluon>'))
    end

    def test_parse_gluon_tag_all
      text = "<html>\n"
      text << "<head><title><gluon name=\"title\" /></title></head>\n"
      text << "<body>\n"
      text << "<h1><gluon name=\"title\" /></h1>\n"
      text << "<p><gluon name=\"message\" /></p>\n"
      text << "<gluon name=\"form?\">\n"
      text << "  <form>\n"
      text << "    <p>\n"
      text << "      <label for=\"memo\">Memo:</label>\n"
      text << "      <gluon name=\"memo\" id=\"memo\" />\n"
      text << "      <gluon name=\"ok\" />\n"
      text << "    </p>\n"
      text << "  </form>\n"
      text << "</gluon>\n"
      text << "</body>\n"
      text << "</html>\n"

      parsed_list = Gluon::CKView.parse(text)
      i = 0

      assert_equal([ :text, "<html>\n<head><title>" ], parsed_list[i])
      i += 1

      assert_equal([ :gluon_tag_single,
                     "<gluon name=\"title\" />",
                     { 'name' => 'title' }
                   ], parsed_list[i])
      i += 1

      assert_equal([ :text, "</title></head>\n<body>\n<h1>" ], parsed_list[i])
      i += 1

      assert_equal([ :gluon_tag_single,
                     "<gluon name=\"title\" />",
                     { 'name' => 'title' }
                   ], parsed_list[i])
      i += 1

      assert_equal([ :text, "</h1>\n<p>" ], parsed_list[i])
      i += 1

      assert_equal([ :gluon_tag_single,
                     "<gluon name=\"message\" />",
                     { 'name' => 'message' }
                   ], parsed_list[i])
      i += 1

      assert_equal([ :text, "</p>\n" ], parsed_list[i])
      i += 1

      assert_equal([ :gluon_tag_start,
                     "<gluon name=\"form?\">",
                     { 'name' => 'form?' }
                   ], parsed_list[i])
      i += 1

      assert_equal([ :text, "\n  <form>\n    <p>\n      <label for=\"memo\">Memo:</label>\n      " ], parsed_list[i])
      i += 1

      assert_equal([ :gluon_tag_single,
                     "<gluon name=\"memo\" id=\"memo\" />",
                     { 'name' => 'memo', 'id' => 'memo' }
                   ], parsed_list[i])
      i += 1

      assert_equal([ :text, "\n      " ], parsed_list[i])
      i += 1

      assert_equal([ :gluon_tag_single,
                     "<gluon name=\"ok\" />",
                     { 'name' => 'ok' }
                   ], parsed_list[i])
      i += 1

      assert_equal([ :text, "\n    </p>\n  </form>\n" ], parsed_list[i])
      i += 1

      assert_equal([ :gluon_tag_end, '</gluon>' ], parsed_list[i])
      i += 1

      assert_equal([ :text, "\n</body>\n</html>\n" ], parsed_list[i])
      i += 1

      assert_equal(i, parsed_list.length)
    end

    def code(*lines)
      lines.map{|t| t + "\n" }.join('')
    end
    private :code

    def test_mkcode_text
      assert_equal(code('@out << "Hello world.\n"'),
                   Gluon::CKView.mkcode([ [ :text, "Hello world.\n" ] ]))
    end

    def test_mkcode_gluon_tag_single
      assert_equal(code('@out << gluon("foo")'),
                   Gluon::CKView.mkcode([ [ :gluon_tag_single,
                                            '<gluon name="foo" />',
                                            { 'name' => 'foo' } ]
                                        ]))
    end

    def test_mkcode_gluon_tag_single_with_attrs
      assert_equal(code('@out << gluon("foo", "bar" => "baz")'),
                   Gluon::CKView.mkcode([ [ :gluon_tag_single,
                                            '<gluon name="foo" bar="baz" />',
                                            { 'name' => 'foo', 'bar' => 'baz' } ]
                                        ]))
    end

    def test_mkcode_gluon_tag_single_without_name
      assert_raise(ArgumentError) {
        Gluon::CKView.mkcode([ [ :gluon_tag_single, '<gluon />', {} ] ])
      }
    end

    def test_mkcode_gluon_tag_starg_end
      assert_equal(code('@out << gluon("foo") {',
                        '}'),
                   Gluon::CKView.mkcode([ [ :gluon_tag_start,
                                            '<gluon name="foo">',
                                            { 'name' => 'foo' } ],
                                          [ :gluon_tag_end,
                                            '</gluon>' ]
                                        ]))
    end

    def test_mkcode_gluon_tag_starg_end_with_attrs
      assert_equal(code('@out << gluon("foo", "bar" => "baz") {',
                        '}'),
                   Gluon::CKView.mkcode([ [ :gluon_tag_start,
                                            '<gluon name="foo" bar="baz">',
                                            { 'name' => 'foo', 'bar' => 'baz' } ],
                                          [ :gluon_tag_end,
                                            '</gluon>' ]
                                        ]))
    end

    def test_mkcode_gluon_tag_starg_end_contains_text
      assert_equal(code('@out << gluon("foo") {',
                        '  @out << "Hello world.\n"',
                        '}'),
                   Gluon::CKView.mkcode([ [ :gluon_tag_start,
                                            '<gluon name="foo">',
                                            { 'name' => 'foo' } ],
                                          [ :text, "Hello world.\n" ],
                                          [ :gluon_tag_end,
                                            '</gluon>' ]
                                        ]))
    end

    def test_mkcode_all_list
      parsed_alist = [
        [ :text, "<html>\n<head><title>" ],
        [ :gluon_tag_single,
          "<gluon name=\"title\" />",
          { 'name' => 'title' } ],
        [ :text, "</title></head>\n<body>\n<h1>" ],
        [ :gluon_tag_single,
          "<gluon name=\"title\" />",
          { 'name' => 'title' } ],
        [ :text, "</h1>\n<p>" ],
        [ :gluon_tag_single,
          "<gluon name=\"message\" />",
          { 'name' => 'message' } ],
        [ :text, "</p>\n" ],
        [ :gluon_tag_start,
          "<gluon name=\"form?\">",
          { 'name' => 'form?' } ],
        [ :text, "\n  <form>\n    <p>\n      <label for=\"memo\">Memo:</label>\n      " ],
        [ :gluon_tag_single,
          "<gluon name=\"memo\" id=\"memo\" />",
          { 'name' => 'memo', 'id' => 'memo' } ],
        [ :text, "\n      " ],
        [ :gluon_tag_single,
          "<gluon name=\"ok\" />",
          { 'name' => 'ok' } ],
        [ :text, "\n    </p>\n  </form>\n" ],
        [ :gluon_tag_end, '</gluon>' ],
        [ :text, "\n</body>\n</html>\n" ]
      ]

      expected_codes = [
        '@out << "<html>\n<head><title>"',
        '@out << gluon("title")',
        '@out << "</title></head>\n<body>\n<h1>"',
        '@out << gluon("title")',
        '@out << "</h1>\n<p>"',
        '@out << gluon("message")',
        '@out << "</p>\n"',
        '@out << gluon("form?") {',
        '  @out << "\n  <form>\n    <p>\n      <label for=\"memo\">Memo:</label>\n      "',
        '  @out << gluon("memo", "id" => "memo")',
        '  @out << "\n      "',
        '  @out << gluon("ok")',
        '  @out << "\n    </p>\n  </form>\n"',
        '}',
        '@out << "\n</body>\n</html>\n"'
      ]

      incremental_parsed_alist = []
      incremental_expected_codes = []
      parsed_alist.zip(expected_codes).each_with_index {|(parsed_item, expected_code), i|
        incremental_parsed_alist << parsed_item
        incremental_expected_codes << expected_code
        assert_equal(code(*incremental_expected_codes),
                     Gluon::CKView.mkcode(incremental_parsed_alist),
                     "#{i}th")
      }
    end
  end

  class CKViewTemplateTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    VIEW_DIR = 'view'

    class AnotherPage
      include Gluon::Controller
      include Gluon::CKView
    end

    def setup
      @view_dir = VIEW_DIR
      FileUtils.rm_rf(@view_dir) # for debug
      FileUtils.mkdir_p(@view_dir)
      @renderer = Gluon::ViewRenderer.new(@view_dir)

      @env = Rack::MockRequest.env_for('http://foo:8080/bar.cgi')
      @env['SCRIPT_NAME'] = '/bar.cgi'
      @env['PATH_INFO'] = ''
      @mock = Gluon::Mock.new(:url_map => { AnotherPage => '/another_page' },
                              :view_dir => @view_dir)
    end

    def teardown
      FileUtils.rm_rf(@view_dir) unless $DEBUG
    end

    def build_page(page_type)
      @c = @mock.new_request(@env)
      @params, @funcs = Gluon::Action.parse(@c.req.params)
      @controller = page_type.new
      @controller.c = @c
      @action = Gluon::Action.new(@controller, @c, @params, @funcs)
      @po = Gluon::PresentationObject.new(@controller, @c, @action)
    end
    private :build_page

    def render_page(ckview_script, filename=nil)
      unless (filename) then
        filename = @c.default_template(@controller) + Gluon::CKView::SUFFIX
      end
      FileUtils.mkdir_p(File.dirname(filename))
      File.open("#{filename}.tmp", 'w') {|out|
        out << ckview_script
      }
      File.rename("#{filename}.tmp", filename) # to change i-node
      @controller.page_render(@po)
    end
    private :render_page

    def assert_optional_attrs(page_type, name)
      build_page(page_type)
      assert_match(/ id="bar"/,
                   render_page(%Q'<gluon name="#{name}" id="bar" />'))
      assert_match(/ id="bar"/,
                   render_page(%Q'<gluon name="#{name}" id="bar"></gluon>'))
      assert_match(/ class="bar"/,
                   render_page(%Q'<gluon name="#{name}" class="bar" />'))
      assert_match(/ class="bar"/,
                   render_page(%Q'<gluon name="#{name}" class="bar"></gluon>'))
      assert_match(/ bar="baz"/,
                   render_page(%Q'<gluon name="#{name}" bar="baz" />'))
      assert_match(/ bar="baz"/,
                   render_page(%Q'<gluon name="#{name}" bar="baz"></gluon>'))
    end
    private :assert_optional_attrs

    class SimplePage
      include Gluon::Controller
      include Gluon::CKView
    end

    def test_text
      build_page(SimplePage)
      assert_equal("Hello world.\n",
                   render_page("Hello world.\n"))
    end

    class PageForValue
      include Gluon::Controller
      include Gluon::CKView

      def foo
        'Hello world.'
      end
      gluon_advice :foo, :type => :value

      def bar
        '&<>" foo'
      end
      gluon_advice :bar, :type => :value, :escape => true

      def baz
        '&<>" foo'
      end
      gluon_advice :baz, :type => :value, :escape => false
    end

    def test_value
      build_page(PageForValue)
      assert_equal('Hello world.',
                   render_page('<gluon name="foo" />'))
    end

    def test_value_with_escape
      build_page(PageForValue)
      assert_equal('&amp;&lt;&gt;&quot; foo',
                   render_page('<gluon name="bar" />'))
    end

    def test_value_with_no_escape
      build_page(PageForValue)
      assert_equal('&<>" foo',
                   render_page('<gluon name="baz" />'))
    end

    def test_value_content_ignored
      build_page(PageForValue)
      assert_equal('Hello world.',
                   render_page('<gluon name="foo">should be ignored.</gluon>'))
    end

    class PageForCond
      include Gluon::Controller
      include Gluon::CKView

      def foo?
        true
      end
      gluon_advice :foo?, :type => :cond

      def bar?
        false
      end
      gluon_advice :bar?, :type => :cond
    end

    def test_cond_true
      build_page(PageForCond)
      assert_equal('HALO', render_page('<gluon name="foo?">HALO</gluon>'))
    end

    def test_cond_false
      build_page(PageForCond)
      assert_equal('', render_page('<gluon name="bar?">HALO</gluon>'))
    end

    class PageForForeach
      include Gluon::Controller
      include Gluon::CKView

      def foo
        %w[ apple banana orange ]
      end
      gluon_advice :foo, :type => :foreach

      def bar
        []
      end
      gluon_advice :bar, :type => :foreach
    end

    def test_foreach
      build_page(PageForForeach)
      assert_equal('[apple][banana][orange]',
                   render_page('<gluon name="foo">[<gluon name="to_s" />]</gluon>'))
    end

    def test_foreach_empty_list
      build_page(PageForForeach)
      assert_equal('',
                   render_page('<gluon name="bar">should be ignored.</gluon>'))
    end

    class PageForLink
      include Gluon::Controller
      include Gluon::CKView

      def foo
        return '/Foo', :text => 'foo'
      end
      gluon_advice :foo, :type => :link
    end

    def test_link
      build_page(PageForLink)
      assert_equal('<a href="/bar.cgi/Foo">foo</a>',
                   render_page('<gluon name="foo" />'))
    end

    def test_link_with_content
      build_page(PageForLink)
      assert_equal('<a href="/bar.cgi/Foo">Hello world.</a>',
                   render_page('<gluon name="foo">Hello world.</gluon>'))
    end

    def test_link_optional_attrs
      assert_optional_attrs(PageForLink, 'foo')
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
