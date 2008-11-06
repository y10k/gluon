#!/usr/local/bin/ruby

require 'gluon'
require 'test/unit'

module Gluon::Test
  class HTMLEmbeddedViewParserTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    def test_parse_attrs
      assert_equal({ 'foo' => 'apple' },
                   Gluon::HTMLEmbeddedView.parse_attrs('foo="apple"'))
    end

    def test_parse_attrs_many
      assert_equal({ 'foo' => 'apple', 'bar' => 'banana' },
                   Gluon::HTMLEmbeddedView.parse_attrs('foo="apple" bar="banana"'))
    end

    def test_parse_attrs_sparsed
      assert_equal({ 'foo' => 'apple', 'bar' => 'banana' },
                   Gluon::HTMLEmbeddedView.parse_attrs(' foo =  "apple"  bar   = "banana" '))
    end

    def test_parse_attrs_densed
      assert_equal({ 'foo' => 'apple', 'bar' => 'banana' },
                   Gluon::HTMLEmbeddedView.parse_attrs('foo="apple"bar="banana"'))
    end

    def test_parse_attrs_single_quoted
      assert_equal({ 'foo' => 'apple' },
                   Gluon::HTMLEmbeddedView.parse_attrs("foo='apple'"))
    end

    def test_parse_attrs_quote_in_double_quoted
      assert_equal({ 'foo' => "'" },
                   Gluon::HTMLEmbeddedView.parse_attrs("foo=\"'\""))
    end

    def test_parse_attrs_quote_in_single_quoted
      assert_equal({ 'foo' => '"' },
                   Gluon::HTMLEmbeddedView.parse_attrs("foo='\"'"))
    end

    def test_parse_attrs_empty
      assert_equal({}, Gluon::HTMLEmbeddedView.parse_attrs(''))
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

    def test_parse_cdata
      assert_equal([ [ :cdata, "Hello world.\n" ] ],
                   Gluon::HTMLEmbeddedView.parse("Hello world.\n"))
    end

    def test_parse_elem_single
      assert_equal([ [ :elem_single, '<foo />', 'foo', {} ] ],
                   Gluon::HTMLEmbeddedView.parse('<foo />'))
    end

    def test_parse_elem_single_with_attrs
      assert_equal([ [ :elem_single,
                       '<foo bar="Apple" baz="Banana" />',
                       'foo',
                       { 'bar' => 'Apple', 'baz' => 'Banana' }
                     ]
                   ],
                   Gluon::HTMLEmbeddedView.parse('<foo bar="Apple" baz="Banana" />'))
    end

    def test_parse_elem_single_sparsed
      assert_equal([ [ :elem_single,
                       "<\nfoo bar  =  'Apple'\tbaz = 'Banana'\n/>",
                       'foo',
                       { 'bar' => 'Apple', 'baz' => 'Banana' }
                     ]
                   ],
                   Gluon::HTMLEmbeddedView.parse("<\nfoo bar  =  'Apple'\tbaz = 'Banana'\n/>"))
    end

    def test_parse_elem_single_densed
      assert_equal([ [ :elem_single,
                       '<foo bar="Apple"baz="Banana"/>',
                       'foo',
                       { 'bar' => 'Apple', 'baz' => 'Banana' }
                     ]
                   ],
                   Gluon::HTMLEmbeddedView.parse('<foo bar="Apple"baz="Banana"/>'))
    end

    def test_parse_elem_start_end
      assert_equal([ [ :elem_start, '<foo>', 'foo', {} ],
                     [ :elem_end, '</foo>', 'foo' ]
                   ],
                   Gluon::HTMLEmbeddedView.parse('<foo></foo>'))
    end

    def test_parse_elem_start_end_with_attrs
      assert_equal([ [ :elem_start,
                       '<foo bar="Apple" baz="Banana">',
                       'foo',
                       { 'bar' => 'Apple', 'baz' => 'Banana' }
                     ],
                     [ :elem_end, '</foo>', 'foo' ]
                   ],
                   Gluon::HTMLEmbeddedView.parse('<foo bar="Apple" baz="Banana"></foo>'))
    end

    def test_parse_elem_start_end_sparsed
      assert_equal([ [ :elem_start,
                       "<\nfoo bar  =  'Apple'\tbaz = 'Banana'\n>",
                       'foo',
                       { 'bar' => 'Apple', 'baz' => 'Banana' }
                     ],
                     [ :elem_end, '</foo>', 'foo' ]
                   ],
                   Gluon::HTMLEmbeddedView.parse("<\nfoo bar  =  'Apple'\tbaz = 'Banana'\n></foo>"))
    end

    def test_parse_elem_start_end_densed
      assert_equal([ [ :elem_start,
                       '<foo bar="Apple"baz="Banana">',
                       'foo',
                       { 'bar' => 'Apple', 'baz' => 'Banana' }
                     ],
                     [ :elem_end, '</foo>', 'foo' ]
                   ],
                   Gluon::HTMLEmbeddedView.parse('<foo bar="Apple"baz="Banana"></foo>'))
    end

    def test_parse_all
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

      parsed_list = Gluon::HTMLEmbeddedView.parse(text)
      i = 0

      assert_equal([ :elem_start,
                     "<html>",
                     "html",
                     {}
                   ],
                   parsed_list[i])
      i += 1

      assert_equal([ :cdata, "\n" ], parsed_list[i])
      i += 1

      assert_equal([ :elem_start,
                     "<head>",
                     "head",
                     {}
                   ],
                   parsed_list[i])
      i += 1

      assert_equal([ :elem_start,
                     "<title gluon=\"title\">",
                     "title",
                     { "gluon" => "title" }
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
                     {}
                   ],
                   parsed_list[i])
      i += 1

      assert_equal([ :cdata, "\n" ], parsed_list[i])
      i += 1

      assert_equal([ :elem_start,
                     "<h1 gluon=\"title\">",
                     "h1",
                     { "gluon" => "title" }
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
                     { "gluon" => "message" }
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
                     { "gluon" => "form?" }
                   ],
                   parsed_list[i])
      i += 1

      assert_equal([ :cdata, "\n  " ], parsed_list[i])
      i += 1

      assert_equal([ :elem_start,
                     "<p>",
                     "p",
                     {}
                   ],
                   parsed_list[i])
      i += 1

      assert_equal([ :cdata, "\n    " ], parsed_list[i])
      i += 1

      assert_equal([ :elem_start,
                     "<label for=\"memo\">",
                     "label",
                     { "for" => "memo" }
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
                     { "gluon" => "memo",
                       "id" => "memo",
                       "name" => "memo",
                       "type" => "text",
                       "value" => "MEMO"
                     }
                   ],
                   parsed_list[i])
      i += 1

      assert_equal([ :cdata, "\n    " ], parsed_list[i])
      i += 1

      assert_equal([ :elem_single,
                     "<input gluon=\"ok\" name=\"ok\" type=\"submit\" />",
                     "input",
                     { "name" => "ok",
                       "gluon" => "ok",
                       "type" => "submit"
                     }
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
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
