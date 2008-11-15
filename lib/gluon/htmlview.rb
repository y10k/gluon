# = gluon - simple web application framework
#
# Author:: $Author$
# Date:: $Date$
# Revision:: $Revision$
#
# == license
#   :include:../LICENSE
#

module Gluon
  # HTML embedded
  module HTMLEmbeddedView
    # for ident(1)
    CVS_ID = '$Id$'

    token = %q![^'"</>&\s]+!
    double_quoted_cdata = %q!"[^"]*"!
    single_quoted_cdata = %q!'[^']*'!
    attr = %Q!#{token}\\s*=\\s*(?:#{double_quoted_cdata}|#{single_quoted_cdata})!
    attrs = %Q!\\s+#{attr}(?:\\s*#{attr})*!
    elem_single = %Q!<\\s*#{token}(?:#{attrs})?\\s*/>!
    elem_start = %Q!<\\s*#{token}(?:#{attrs})?\\s*>!
    elem_end = %Q!</\\s*#{token}\\s*>!

    ATTR_PARSE_PATTERN = %r!(#{token})\s*=\s*(#{double_quoted_cdata}|#{single_quoted_cdata})!m
    ELEM_PARSE_PATTERN = %r!^</?\s*(#{token})!
    HTML_PARSE_PATTERN = %r!(?:(.*?)(?:(#{elem_single})|(#{elem_start})|(#{elem_end})))|(.+)\z!m

    class << self
      def parse_attrs(element)
        attrs = []
        element.scan(ATTR_PARSE_PATTERN) do
          name = $1.downcase
          value = $2
          value.sub!(/^["']/, '')
          value.sub!(/["']$/, '')
          attrs << [ name, value ]
        end
        attrs
      end

      def parse_elem_name(element)
        element =~ ELEM_PARSE_PATTERN or raise "not a HTML element: #{element}"
        $1
      end

      def parse_html(text)
        parsed_list = []
        text.scan(HTML_PARSE_PATTERN) do
          cdata = $1
          elem_single = $2
          elem_start = $3
          elem_end = $4
          tail = $5

          if (cdata && ! cdata.empty?) then
            parsed_list << [
              :cdata,
              cdata
            ]
          end

          if (elem_single) then
            parsed_list << [
              :elem_single,
              elem_single,
              parse_elem_name(elem_single),
              parse_attrs(elem_single)
            ]
          end

          if (elem_start) then
            parsed_list << [
              :elem_start,
              elem_start,
              parse_elem_name(elem_start),
              parse_attrs(elem_start)
            ]
          end

          if (elem_end) then
            parsed_list << [
              :elem_end,
              elem_end,
              parse_elem_name(elem_end)
            ]
          end

          if (tail && ! tail.empty?) then
            parsed_list << [
              :cdata,
              tail
            ]
          end
        end

        parsed_list
      end

      def parse_inline(text)
        parsed_list = []
        text.scan(/(.*?)(\$\{.*?\}|\$\$)|(.+)\z/m) do
          cdata = $1
          special = $2
          tail = $3

          if (cdata && ! cdata.empty?) then
            parsed_list << [ :text, cdata ]
          end

          if (special) then
            case (special)
            when /^\$\{/
              name = special.sub(/^\$\{/, '').sub(/\}$/, '')
              parsed_list << [ :gluon, name ]
            when '$$'
              parsed_list << [ :text, '$' ]
            else
              raise "unknown special syntax: #{special}"
            end
          end

          if (tail && ! tail.empty?) then
            parsed_list << [ :text, tail ]
          end
        end

        parsed_list
      end

      def append_text(expr_list, text)
        if (expr_list.empty? || expr_list.last[0] != :text) then
          expr_list << [ :text, text.dup ]
        else
          expr_list.last[1] << text
        end
        nil
      end
      private :append_text

      def append_elem_start(expr_list, elem_name, attrs)
        append_text(expr_list, "<#{elem_name}")
        for name, value in attrs
          quote = (value =~ /"/) ? "'" : '"'
          append_text(expr_list, %Q' #{name}=#{quote}')
          for type, text in parse_inline(value)
            case (type)
            when :text
              append_text(expr_list, text)
            when :gluon
              expr_list << [
                :gluon_tag_single,
                text,
                :inline,
                []
              ]
            else
              raise "unknown inline syntax type: #{type}"
            end
          end
          append_text(expr_list, quote)
        end
        nil
      end
      private :append_elem_start

      def append_gluon(expr_list, type, name, elem_name, attrs)
        expr_list << [
          type,
          name,
          elem_name,
          attrs.reject{|n, v| n.downcase == 'gluon' }
        ]
        nil
      end
      private :append_gluon

      def mkexpr(html_list)
        expr_list = []
        for type, src, name, attrs in html_list
          case (type)
          when :cdata
            append_text(expr_list, src)
          when :elem_single
            if (gluon_attr = attrs.find{|n,v| n.downcase == 'gluon' }) then
              append_gluon(expr_list,
                           :gluon_tag_single, gluon_attr[1],
                           name, attrs)
            elsif (attrs.find{|n,v| v.index('$') }) then
              append_elem_start(expr_list, name, attrs)
              append_text(expr_list, ' />')
            else
              append_text(expr_list, src)
            end
          when :elem_start
            raise NotImplementedError, 'now implementing...'
          when :elem_end
            raise NotImplementedError, 'now implementing...'
          else
            raise "unknown parsed type: #{type}"
          end
        end

        expr_list
      end
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
