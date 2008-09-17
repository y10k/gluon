#!/usr/local/bin/ruby

require 'gluon'
require 'test/unit'

module Gluon::Test
  class CKViewTest < Test::Unit::TestCase
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
      text << "<head><title><gluon refkey=\"title\" /></title></head>\n"
      text << "<body>\n"
      text << "<h1><gluon refkey=\"title\" /></h1>\n"
      text << "<p><gluon refkey=\"message\" /></p>\n"
      text << "<gluon refkey=\"form?\">\n"
      text << "  <form>\n"
      text << "    <p>\n"
      text << "      <label for=\"memo\">Memo:</label>\n"
      text << "      <gluon refkey=\"memo\" id=\"memo\" />\n"
      text << "      <gluon refkey=\"ok\" />\n"
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
                     "<gluon refkey=\"title\" />",
                     { 'refkey' => 'title' }
                   ], parsed_list[i])
      i += 1

      assert_equal([ :text, "</title></head>\n<body>\n<h1>" ], parsed_list[i])
      i += 1

      assert_equal([ :gluon_tag_single,
                     "<gluon refkey=\"title\" />",
                     { 'refkey' => 'title' }
                   ], parsed_list[i])
      i += 1

      assert_equal([ :text, "</h1>\n<p>" ], parsed_list[i])
      i += 1

      assert_equal([ :gluon_tag_single,
                     "<gluon refkey=\"message\" />",
                     { 'refkey' => 'message' }
                   ], parsed_list[i])
      i += 1

      assert_equal([ :text, "</p>\n" ], parsed_list[i])
      i += 1

      assert_equal([ :gluon_tag_start,
                     "<gluon refkey=\"form?\">",
                     { 'refkey' => 'form?' }
                   ], parsed_list[i])
      i += 1

      assert_equal([ :text, "\n  <form>\n    <p>\n      <label for=\"memo\">Memo:</label>\n      " ], parsed_list[i])
      i += 1

      assert_equal([ :gluon_tag_single,
                     "<gluon refkey=\"memo\" id=\"memo\" />",
                     { 'refkey' => 'memo', 'id' => 'memo' }
                   ], parsed_list[i])
      i += 1

      assert_equal([ :text, "\n      " ], parsed_list[i])
      i += 1

      assert_equal([ :gluon_tag_single,
                     "<gluon refkey=\"ok\" />",
                     { 'refkey' => 'ok' }
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
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
