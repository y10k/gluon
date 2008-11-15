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
        elem_stack_map = {}
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
            elem_key = name.downcase
            elem_stack_map[elem_key] = [] unless (elem_stack_map.key? elem_key)
            if (gluon_attr = attrs.find{|n,v| n.downcase == 'gluon' }) then
              elem_stack_map[elem_key].push(true)
              append_gluon(expr_list,
                           :gluon_tag_start, gluon_attr[1],
                           name, attrs)
            elsif (attrs.find{|n,v| v.index('$') }) then
              elem_stack_map[elem_key].push(false)
              append_elem_start(expr_list, name, attrs)
              append_text(expr_list, '>')
            else
              elem_stack_map[elem_key].push(false)
              append_text(expr_list, src)
            end
          when :elem_end
            elem_key = name.downcase
            if (elem_stack_map.key? elem_key) then
              is_gluon = elem_stack_map[elem_key].pop
            else
              is_gluon = false
            end
            if (is_gluon) then
              expr_list << [ :gluon_tag_end, src ]
            else
              append_text(expr_list, src)
            end
          else
            raise "unknown html type: #{type}"
          end
        end

        expr_list
      end

      def mkopts(attrs)
        attrs.map{|k, v| "[ #{k.dump}, #{v.dump} ]" }.join(', ')
      end
      private :mkopts

      def mkind(indent_level)
        '  ' * indent_level
      end
      private :mkind

      def dump_s(value)
        case (value)
        when String
          value.dump
        when Symbol
          ':' + value.to_s
        else
          raise "not a String or Symbol: #{value}"
        end
      end
      private :dump_s

      def mkcode(expr_list)
        r = ''
        ind = 0
        for type, name, elem_name, attrs in expr_list
          case (type)
          when :text
            r << mkind(ind) << "@out << #{name.dump}\n"
          when :gluon_tag_single
            r << mkind(ind)
            r << "@out << gluon(#{name.dump}, #{dump_s(elem_name)}"
            r << ', ' << mkopts(attrs) unless attrs.empty?
            r << ")\n"
          when :gluon_tag_start
            r << mkind(ind)
            r << "@out << gluon(#{name.dump}, #{dump_s(elem_name)}"
            r << ', ' << mkopts(attrs) unless attrs.empty?
            r << ") {\n"
            ind += 1
          when :gluon_tag_end
            ind -= 1
            r << mkind(ind) << "}\n"
          else
            raise "unknown expr type: #{type}"
          end
        end

        r
      end
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
