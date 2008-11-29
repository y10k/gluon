#!/usr/local/bin/ruby

require 'gluon'
require 'test/unit'
require 'view_test_helper'

module Gluon::Test
  class HTMLEmbeddedViewParserTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    def test_parse_attrs
      assert_equal([ %w[ foo apple ] ],
                   Gluon::HTMLEmbeddedView.parse_attrs('foo="apple"'))
    end

    def test_parse_attrs_many
      assert_equal([ %w[ foo apple ], %w[ bar banana ] ],
                   Gluon::HTMLEmbeddedView.parse_attrs('foo="apple" bar="banana"'))
    end

    def test_parse_attrs_sparsed
      assert_equal([ %w[ foo apple ], %w[ bar banana ] ],
                   Gluon::HTMLEmbeddedView.parse_attrs(' foo =  "apple"  bar   = "banana" '))
    end

    def test_parse_attrs_densed
      assert_equal([ %w[ foo apple ], %w[ bar banana ] ],
                   Gluon::HTMLEmbeddedView.parse_attrs('foo="apple"bar="banana"'))
    end

    def test_parse_attrs_single_quoted
      assert_equal([ %w[ foo apple ] ],
                   Gluon::HTMLEmbeddedView.parse_attrs("foo='apple'"))
    end

    def test_parse_attrs_quote_in_double_quoted
      assert_equal([ %w[ foo ' ] ],
                   Gluon::HTMLEmbeddedView.parse_attrs("foo=\"'\""))
    end

    def test_parse_attrs_quote_in_single_quoted
      assert_equal([ %w[ foo " ] ],
                   Gluon::HTMLEmbeddedView.parse_attrs("foo='\"'"))
    end

    def test_parse_attrs_empty
      assert_equal([], Gluon::HTMLEmbeddedView.parse_attrs(''))
    end

    def test_parse_elem_name
      assert_equal('foo', Gluon::HTMLEmbeddedView.parse_elem_name('<foo>'))
    end

    def test_parse_elem_name_sparsed
      assert_equal('foo', Gluon::HTMLEmbeddedView.parse_elem_name('< foo  >'))
    end

    def test_parse_elem_name_attrs
      assert_equal('foo', Gluon::HTMLEmbeddedView.parse_elem_name('<foo bar="baz">'))
    end

    def test_parse_elem_name_single
      assert_equal('foo', Gluon::HTMLEmbeddedView.parse_elem_name('<foo/>'))
    end

    def test_parse_elem_name_sparsed
      assert_equal('foo', Gluon::HTMLEmbeddedView.parse_elem_name('< foo  />'))
    end

    def test_parse_elem_name_single_attrs
      assert_equal('foo', Gluon::HTMLEmbeddedView.parse_elem_name('<foo bar="baz" />'))
    end

    def test_parse_elem_name_end
      assert_equal('foo', Gluon::HTMLEmbeddedView.parse_elem_name('</foo>'))
    end

    def test_parse_elem_name_end_sparsed
      assert_equal('foo', Gluon::HTMLEmbeddedView.parse_elem_name('</ foo  >'))
    end

    def test_parse_html_cdata
      assert_equal([ [ :cdata, "Hello world.\n" ] ],
                   Gluon::HTMLEmbeddedView.parse_html("Hello world.\n"))
    end

    def test_parse_html_elem_single
      assert_equal([ [ :elem_single, '<foo />', 'foo', [] ] ],
                   Gluon::HTMLEmbeddedView.parse_html('<foo />'))
    end

    def test_parse_html_elem_single_attrs
      assert_equal([ [ :elem_single,
                       '<foo bar="Apple" baz="Banana" />',
                       'foo',
                       [ %w[ bar Apple ], %w[ baz Banana ] ]
                     ]
                   ],
                   Gluon::HTMLEmbeddedView.parse_html('<foo bar="Apple" baz="Banana" />'))
    end

    def test_parse_html_elem_single_sparsed
      assert_equal([ [ :elem_single,
                       "<\nfoo bar  =  'Apple'\tbaz = 'Banana'\n/>",
                       'foo',
                       [ %w[ bar Apple ], %w[ baz  Banana ] ]
                     ]
                   ],
                   Gluon::HTMLEmbeddedView.parse_html("<\nfoo bar  =  'Apple'\tbaz = 'Banana'\n/>"))
    end

    def test_parse_html_elem_single_densed
      assert_equal([ [ :elem_single,
                       '<foo bar="Apple"baz="Banana"/>',
                       'foo',
                       [ %w[ bar Apple ], %w[ baz Banana ] ]
                     ]
                   ],
                   Gluon::HTMLEmbeddedView.parse_html('<foo bar="Apple"baz="Banana"/>'))
    end

    def test_parse_elem_start_end
      assert_equal([ [ :elem_start, '<foo>', 'foo', [] ],
                     [ :elem_end, '</foo>', 'foo' ]
                   ],
                   Gluon::HTMLEmbeddedView.parse_html('<foo></foo>'))
    end

    def test_parse_html_elem_start_end_attrs
      assert_equal([ [ :elem_start,
                       '<foo bar="Apple" baz="Banana">',
                       'foo',
                       [ %w[ bar Apple ], %w[ baz Banana ] ]
                     ],
                     [ :elem_end, '</foo>', 'foo' ]
                   ],
                   Gluon::HTMLEmbeddedView.parse_html('<foo bar="Apple" baz="Banana"></foo>'))
    end

    def test_parse_elem_start_end_sparsed
      assert_equal([ [ :elem_start,
                       "<\nfoo bar  =  'Apple'\tbaz = 'Banana'\n>",
                       'foo',
                       [ %w[ bar Apple ], %w[ baz Banana ] ]
                     ],
                     [ :elem_end, '</foo>', 'foo' ]
                   ],
                   Gluon::HTMLEmbeddedView.parse_html("<\nfoo bar  =  'Apple'\tbaz = 'Banana'\n></foo>"))
    end

    def test_parse_html_elem_start_end_densed
      assert_equal([ [ :elem_start,
                       '<foo bar="Apple"baz="Banana">',
                       'foo',
                       [ %w[ bar Apple ], %w[ baz Banana ] ]
                     ],
                     [ :elem_end, '</foo>', 'foo' ]
                   ],
                   Gluon::HTMLEmbeddedView.parse_html('<foo bar="Apple"baz="Banana"></foo>'))
    end

    def test_parse_html_all
      text = "<html>\n"
      text << "<head><title gluon=\"title\">TITLE</title></head>\n"
      text << "<body>\n"
      text << "<h1 gluon=\"title\">TITLE</h1>\n"
      text << "<p gluon=\"message\">MESSAGE</p>\n"
      text << "<form gluon=\"form?\">\n"
      text << "  <p>\n"
      text << "    <label for=\"memo\">Memo:</label>\n"
      text << "    <input gluon=\"memo\" id=\"memo\" name=\"memo\" type=\"text\" value=\"MEMO\" />\n"
      text << "    <input gluon=\"ok\" name=\"ok\" type=\"submit\" />\n"
      text << "  </p>\n"
      text << "</form>\n"
      text << "</body>\n"
      text << "</html>\n"

      parsed_list = Gluon::HTMLEmbeddedView.parse_html(text)
      i = 0

      assert_equal([ :elem_start,
                     "<html>",
                     "html",
                     []
                   ],
                   parsed_list[i])
      i += 1

      assert_equal([ :cdata, "\n" ], parsed_list[i])
      i += 1

      assert_equal([ :elem_start,
                     "<head>",
                     "head",
                     []
                   ],
                   parsed_list[i])
      i += 1

      assert_equal([ :elem_start,
                     "<title gluon=\"title\">",
                     "title",
                     [ %w[ gluon title ] ]
                   ],
                   parsed_list[i])
      i += 1

      assert_equal([ :cdata, "TITLE" ], parsed_list[i])
      i += 1

      assert_equal([ :elem_end, "</title>", "title" ], parsed_list[i])
      i += 1

      assert_equal([ :elem_end, "</head>", "head" ], parsed_list[i])
      i += 1

      assert_equal([ :cdata, "\n" ], parsed_list[i])
      i += 1

      assert_equal([ :elem_start,
                     "<body>",
                     "body",
                     []
                   ],
                   parsed_list[i])
      i += 1

      assert_equal([ :cdata, "\n" ], parsed_list[i])
      i += 1

      assert_equal([ :elem_start,
                     "<h1 gluon=\"title\">",
                     "h1",
                     [ %w[ gluon title ] ]
                   ],
                   parsed_list[i])
      i += 1

      assert_equal([ :cdata, "TITLE" ], parsed_list[i])
      i += 1

      assert_equal([ :elem_end, "</h1>", "h1" ], parsed_list[i])
      i += 1

      assert_equal([ :cdata, "\n" ], parsed_list[i])
      i += 1

      assert_equal([ :elem_start,
                     "<p gluon=\"message\">",
                     "p",
                     [ %w[ gluon message ] ]
                   ],
                   parsed_list[i])
      i += 1

      assert_equal([ :cdata, "MESSAGE" ], parsed_list[i])
      i += 1

      assert_equal([ :elem_end, "</p>", "p" ], parsed_list[i])
      i += 1

      assert_equal([ :cdata, "\n" ], parsed_list[i])
      i += 1

      assert_equal([ :elem_start,
                     "<form gluon=\"form?\">",
                     "form",
                     [ %w[ gluon form? ] ]
                   ],
                   parsed_list[i])
      i += 1

      assert_equal([ :cdata, "\n  " ], parsed_list[i])
      i += 1

      assert_equal([ :elem_start,
                     "<p>",
                     "p",
                     []
                   ],
                   parsed_list[i])
      i += 1

      assert_equal([ :cdata, "\n    " ], parsed_list[i])
      i += 1

      assert_equal([ :elem_start,
                     "<label for=\"memo\">",
                     "label",
                     [ %w[ for memo ] ]
                   ],
                   parsed_list[i])
      i += 1

      assert_equal([ :cdata, "Memo:" ], parsed_list[i])
      i += 1

      assert_equal([ :elem_end, "</label>", "label" ], parsed_list[i])
      i += 1

      assert_equal([ :cdata, "\n    " ], parsed_list[i])
      i += 1

      assert_equal([ :elem_single,
                     "<input gluon=\"memo\" id=\"memo\" name=\"memo\" type=\"text\" value=\"MEMO\" />",
                     "input",
                     [ %w[ gluon memo ],
                       %w[ id memo ],
                       %w[ name memo ],
                       %w[ type text ],
                       %w[ value MEMO ]
                     ]
                   ],
                   parsed_list[i])
      i += 1

      assert_equal([ :cdata, "\n    " ], parsed_list[i])
      i += 1

      assert_equal([ :elem_single,
                     "<input gluon=\"ok\" name=\"ok\" type=\"submit\" />",
                     "input",
                     [ %w[ gluon ok ],
                       %w[ name ok ],
                       %w[ type submit ]
                     ]
                   ],
                   parsed_list[i])
      i += 1

      assert_equal([ :cdata, "\n  " ], parsed_list[i])
      i += 1

      assert_equal([ :elem_end, "</p>", "p" ], parsed_list[i])
      i += 1

      assert_equal([ :cdata, "\n" ], parsed_list[i])
      i += 1

      assert_equal([ :elem_end, "</form>", "form" ], parsed_list[i])
      i += 1

      assert_equal([ :cdata, "\n" ], parsed_list[i])
      i += 1

      assert_equal([ :elem_end, "</body>", "body" ], parsed_list[i])
      i += 1

      assert_equal([ :cdata, "\n" ], parsed_list[i])
      i += 1

      assert_equal([ :elem_end, "</html>", "html" ], parsed_list[i])
      i += 1

      assert_equal([ :cdata, "\n" ], parsed_list[i])
      i += 1

      assert_equal(i, parsed_list.length)
    end

    def test_parse_inline_cdata
      assert_equal([ [ :text, 'Hello world.' ] ],
                   Gluon::HTMLEmbeddedView.parse_inline('Hello world.'))
    end

    def test_parse_inline_special
      assert_equal([ [ :gluon, 'foo' ] ],
                   Gluon::HTMLEmbeddedView.parse_inline('${foo}'))
    end

    def test_parse_inline_cdata_special
      assert_equal([ [ :text, 'foo ' ],
                     [ :gluon, 'bar' ],
                     [ :text, ' baz' ]
                   ],
                   Gluon::HTMLEmbeddedView.parse_inline('foo ${bar} baz'))
    end

    def test_parse_inline_escaped_special
      assert_equal([ [ :text, '$' ],
                     [ :text, '{foo}' ]
                   ],
                   Gluon::HTMLEmbeddedView.parse_inline('$${foo}'))
    end

    # shortcut
    def mkexpr(*args)
      Gluon::HTMLEmbeddedView.mkexpr(*args)
    end
    private :mkexpr

    def test_mkexpr_cdata
      assert_equal([ [ :text, "Hello world.\n" ] ],
                   mkexpr([ [ :cdata, "Hello world.\n" ] ]))
    end

    def test_mkexpr_cdata_compaction
      assert_equal([ [ :text, "Hello world.\n" ] ],
                   mkexpr([ [ :cdata, 'Hello' ],
                            [ :cdata, ' world.' ],
                            [ :cdata, "\n" ]
                          ]))
    end

    def test_mkexpr_elem_single
      assert_equal([ [ :text, '<foo bar="Apple" baz="Banana" />' ] ],
                   mkexpr([ [ :elem_single,
                              '<foo bar="Apple" baz="Banana" />',
                              'foo',
                              [ %w[ bar Apple ], %w[ baz Banana ] ]
                            ]
                          ]))
    end

    def test_mkexpr_elem_single_gluon
      assert_equal([ [ :gluon_tag_single, 'foo', 'span', [] ] ],
                   mkexpr([ [ :elem_single,
                              '<span gluon="foo" />',
                              'span',
                              [ %w[ gluon foo ] ]
                            ]
                          ]))
    end

    def test_mkexpr_elem_single_gluon_attrs
      assert_equal([ [ :gluon_tag_single, 
                       'foo',
                       'span',
                       [ %w[ id foo ],
                         %w[ class message ]
                       ]
                     ]
                   ],
                   mkexpr([ [ :elem_single,
                              '<span gluon="foo" id="foo" class="message" />',
                              'span',
                              [ %w[ gluon foo ],
                                %w[ id foo ],
                                %w[ class message ]
                              ]
                            ]
                          ]))
    end

    def test_mkexpr_elem_single_gluon_inline_syntax
      assert_equal([ [ :text, '<span id="' ],
                     [ :gluon_tag_single,
                       'foo',
                       :inline,
                       []
                     ],
                     [ :text, '" />' ]
                   ],
                   mkexpr([ [ :elem_single,
                              '<span id="${foo}" />',
                              'span',
                              [ [ 'id', '${foo}' ] ]
                            ]
                          ]))
    end

    def test_mkexpr_elem_single_gluon_inline_syntax_attrs
      assert_equal([ [ :text, '<span id="' ],
                     [ :gluon_tag_single,
                       'foo',
                       :inline,
                       []
                     ],
                     [ :text, '" class="message" />' ]
                   ],
                   mkexpr([ [ :elem_single,
                              '<span id="${foo}" class="message" />',
                              'span',
                              [ [ 'id', '${foo}' ],
                                [ 'class', 'message' ]
                              ]
                            ]
                          ]))
    end

    def test_mkexpr_elem_single_gluon_inline_syntax_special_characters
      assert_equal([ [ :text, '<span id="' ],
                     [ :gluon_tag_single,
                       'foo',
                       :inline,
                       []
                     ],
                     [ :text, "\" title='$ $$ \"$foo\"' />" ]
                   ],
                   mkexpr([ [ :elem_single,
                              "<span id=\"${foo}\" title='$$ $$$$ \"$foo\"' />",
                              'span',
                              [ [ 'id', '${foo}' ],
                                [ 'title', '$$ $$$$ "$foo"' ]
                              ]
                            ]
                          ]))
    end

    def test_mkexpr_elem_start_end
      assert_equal([ [ :text, '<p id="foo">Hello world.</p>' ] ],
                   mkexpr([ [ :elem_start,
                              '<p id="foo">',
                              'p',
                              [ %w[ id foo ] ]
                            ],
                            [ :cdata, 'Hello world.' ],
                            [ :elem_end, '</p>', 'p' ]
                          ]))
    end

    def test_mkexpr_elem_start_end_unbalanced_elem_start
      assert_equal([ [ :text, '<p><p id="foo">Hello world.</p>' ] ],
                   mkexpr([ [ :elem_start,
                              '<p>',
                              'p',
                              []
                            ],
                            [ :elem_start,
                              '<p id="foo">',
                              'p',
                              [ %w[ id foo ] ]
                            ],
                            [ :cdata, 'Hello world.' ],
                            [ :elem_end, '</p>', 'p' ]
                          ]))
    end

    def test_mkexpr_elem_start_end_unbalanced_elem_end
      assert_equal([ [ :text, '<p id="foo">Hello world.</p></p>' ] ],
                   mkexpr([ [ :elem_start,
                              '<p id="foo">',
                              'p',
                              [ %w[ id foo ] ]
                            ],
                            [ :cdata, 'Hello world.' ],
                            [ :elem_end, '</p>', 'p' ],
                            [ :elem_end, '</p>', 'p' ]
                          ]))
    end

    def test_mkexpr_elem_start_end_gluon
      assert_equal([ [ :gluon_tag_start,
                       'foo',
                       'p',
                       []
                     ],
                     [ :text, 'Hello world.' ],
                     [ :gluon_tag_end, '</p>' ]
                   ],
                   mkexpr([ [ :elem_start,
                              '<p gluon="foo">',
                              'p',
                              [ %w[ gluon foo ] ]
                            ],
                            [ :cdata, 'Hello world.' ],
                            [ :elem_end, '</p>', 'p' ]
                          ]))
    end

    def test_mkexpr_elem_start_end_gluon_inline_syntax
      assert_equal([ [ :text, '<p title="{' ],
                     [ :gluon_tag_single,
                       'foo',
                       :inline,
                       []
                     ],
                     [ :text, '} $ $$ $foo">Hello world.</p>' ]
                   ],
                   mkexpr([ [ :elem_start,
                              '<p title="{${foo}} $$ $$$$ $foo">',
                              'p',
                              [ [ 'title', '{${foo}} $$ $$$$ $foo' ] ]
                            ],
                            [ :cdata, 'Hello world.' ],
                            [ :elem_end, '</p>', 'p' ]
                          ]))
    end

    def code(*lines)
      lines.map{|t| t + "\n" }.join('')
    end
    private :code

    # shortcut
    def mkcode(*args)
      Gluon::HTMLEmbeddedView.mkcode(*args)
    end
    private :mkcode

    def test_mkcode_text
      assert_equal(code('@out << "Hello world.\n"'),
                   mkcode([ [ :text, "Hello world.\n" ] ]))
    end

    def test_mkcode_gluon_tag_single
      assert_equal(code('@out << gluon("foo", "p")'),
                   mkcode([ [ :gluon_tag_single,
                              'foo',
                              'p',
                              []
                            ]
                          ]))
    end

    def test_mkcode_gluon_tag_single_attrs
      assert_equal(code('@out << gluon("foo", "p", [ "id", "foo" ], [ "class", "message" ])'),
                   mkcode([ [ :gluon_tag_single,
                              'foo',
                              'p',
                              [ %w[ id foo ], %w[ class message ] ]
                            ]
                          ]))
    end

    def test_mkcode_gluon_tag_single_inline
      assert_equal(code('@out << "<span id=\""',
                        '@out << gluon("foo", :inline)',
                        '@out << "\" />"'),
                   mkcode([ [ :text, '<span id="' ],
                            [ :gluon_tag_single,
                              'foo',
                              :inline,
                              []
                            ],
                            [ :text, '" />' ]
                          ]))
    end

    def test_mkcode_gluon_tag_start_end
      assert_equal(code('@out << gluon("foo", "p") {',
                        '}'),
                   mkcode([ [ :gluon_tag_start,
                              'foo',
                              'p',
                              []
                            ],
                            [ :gluon_tag_end, '</p>' ]
                          ]))
    end

    def test_mkcode_gluon_tag_start_end_attrs
      assert_equal(code('@out << gluon("foo", "p", [ "id", "foo" ], [ "class", "message" ]) {',
                        '}'),
                   mkcode([ [ :gluon_tag_start,
                              'foo',
                              'p',
                              [ %w[ id foo ], %w[ class message ] ],
                            ],
                            [ :gluon_tag_end, '</p>' ]
                          ]))
    end

    def test_mkcode_gluon_tag_start_end_contains_text
      assert_equal(code('@out << gluon("foo", "p") {',
                        '  @out << "Hello world.\n"',
                        '}'),
                   mkcode([ [ :gluon_tag_start,
                              'foo',
                              'p',
                              [],
                            ],
                            [ :text, "Hello world.\n" ],
                            [ :gluon_tag_end, '</p>' ]
                          ]))
    end
  end

  class HTMLEmbeddedViewTemplateTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    include ViewTestHelper

    def target_view_module
      Gluon::HTMLEmbeddedView
    end

    def view_template_simple
      "Hello world.\n"
    end

    def view_template_value
      '<span gluon="foo" />'
    end

    def view_expected_value
      "<span>#{super}</span>"
    end

    def view_template_value_escape
      '<span gluon="bar" />'
    end

    def view_expected_value_escape
      "<span>#{super}</span>"
    end

    def view_template_value_no_escape
      '<span gluon="baz" />'
    end

    def view_expected_value_no_escape
      "<span>#{super}</span>"
    end

    def view_template_value_content_ignored
      '<span gluon="foo">should be ignored.</span>'
    end

    def view_expected_value_content_ignored
      "<span>#{super}</span>"
    end

    def view_template_cond_true
      '<span gluon="foo?">should be picked up.</span>'
    end

    def view_expected_cond_true
      "<span>#{super}</span>"
    end

    def view_template_cond_false
      '<span gluon="bar?">should be ignored.</span>'
    end

    def view_template_foreach
      '<ol gluon="foo"><li gluon="to_s" /></ol>'
    end

    def view_template_foreach_empty_list
      '<ol gluon="bar">should be ignored.</ol>'
    end

    def view_expected_foreach_empty_list
      "<ol>#{super}</ol>"
    end

    def view_template_link
      '<a gluon="foo" />'
    end

    def view_template_link_content
      '<a gluon="foo">should be picked up.</a>'
    end

    def view_template_link_embedded_attrs
      '<a gluon="foo" foo="Apple" bar="Banana" baz="baz" />'
    end

    def view_template_link_class
      '<a gluon="bar" />'
    end

    def view_template_action
      '<a gluon="foo" />'
    end

    def view_template_action_text
      '<a gluon="bar" />'
    end

    def view_template_action_content
      '<a gluon="bar">should be picked up.</a>'
    end

    def view_template_action_embedded_attrs
      '<a gluon="foo" foo="Apple" bar="Banana" baz="baz" />'
    end

    def view_template_frame
      '<frame gluon="foo" />'
    end

    def view_template_frame_content_ignored
      '<frame gluon="foo">should be ignored.</frame>'
    end

    def view_template_frame_class
      '<frame gluon="bar" />'
    end

    def view_template_frame_embedded_attrs
      '<frame gluon="foo" foo="Apple" bar="Banana" baz="baz" />'
    end

    def view_template_import
      '[<div gluon="foo" />]'
    end

    def view_template_import_content
      '<div gluon="bar">should be picked up.</div>'
    end

    def view_template_import_content_default
      '<div gluon="baz" />'
    end

    def view_template_import_content_not_defined
      '<div gluon="bar" />'
    end

    def view_template_text
      '<input gluon="foo" />'
    end

    def view_template_text_value
      '<input gluon="bar" />'
    end

    def view_template_text_content_ignored
      '<input gluon="foo">should be ignored.</input>'
    end

    def view_template_text_embedded_attrs
      '<input gluon="foo" foo="Apple" bar="Banana" baz="baz" />'
    end

    def view_template_password
      '<input gluon="foo" />'
    end

    def view_template_password_value
      '<input gluon="bar" />'
    end

    def view_template_password_content_ignored
      '<input gluon="foo">should be ignored.</input>'
    end

    def view_template_password_embedded_attrs
      '<input gluon="foo" foo="Apple" bar="Banana" baz="baz" />'
    end

    def view_template_submit
      '<input gluon="foo" />'
    end

    def view_template_submit_value
      '<input gluon="bar" value="should be picked up." />'
    end

    def view_template_submit_content_ignored
      '<input gluon="foo">should be ignored.</input>'
    end

    def view_template_submit_embedded_attrs
      '<input gluon="foo" foo="Apple" bar="Banana" baz="baz" />'
    end

    def view_template_hidden
      '<input gluon="foo" />'
    end

    def view_template_hidden_value
      '<input gluon="bar" />'
    end

    def view_template_hidden_content_ignored
      '<input gluon="foo">should be ignored.</input>'
    end

    def view_template_hidden_embedded_attrs
      '<input gluon="foo" foo="Apple" bar="Banana" baz="baz" />'
    end

    def view_template_checkbox
      '<input gluon="foo" />'
    end

    def view_template_checkbox_checked
      '<input gluon="bar" />'
    end

    def view_template_checkbox_content_ignored
      '<input gluon="foo">should be ignored.</input>'
    end

    def view_template_checkbox_embedded_attrs
      '<input gluon="foo" foo="Apple" bar="Banana" baz="baz" />'
    end

    def view_template_radio
      '<input gluon="foo=apple" />'
    end

    def view_template_radio_checked
      '<input gluon="foo=banana" />'
    end

    def view_template_radio_content_ignored
      '<input gluon="foo=apple">should be ignored.</input>'
    end

    def view_template_radio_embedded_attrs
      '<input gluon="foo=apple" foo="Apple" bar="Banana" baz="baz" />'
    end

    def view_template_select
      '<input gluon="foo" />'
    end

    def view_template_select_content_ignored
      '<input gluon="foo">should be ignored.</input>'
    end

    def view_template_select_multiple
      '<select gluon="bar" />'
    end

    def view_template_select_embedded_attrs
      '<select gluon="foo" foo="Apple" bar="Banana" baz="baz" />'
    end

    def view_template_textarea
      '<textarea gluon="foo" />'
    end

    def view_template_textarea_value
      '<textarea gluon="bar" />'
    end

    def view_template_textarea_content_ignored
      '<textarea gluon="foo">should be ignored.</textarea>'
    end

    def view_template_textarea_embedded_attrs
      '<textarea gluon="foo" foo="Apple" bar="Banana" baz="baz" />'
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
