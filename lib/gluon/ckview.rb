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
  # template like CGIKit 1.x
  module CKView
    # for ident(1)
    CVS_ID = '$Id$'

    token = %q![^'"<>&\s]+!
    double_quoted_cdata = %q!"[^"]*"!
    single_quoted_cdata = %q!'[^']*'!
    attr = %Q!#{token}\\s*=\\s*(?:#{double_quoted_cdata}|#{single_quoted_cdata})!
    attrs = %Q!\\s+#{attr}(?:\\s*#{attr})*!
    gluon_tag_single = %Q!<\\s*gluon(?:#{attrs})?\\s*/>!
    gluon_tag_start = %Q!<\\s*gluon(?:#{attrs})?\\s*>!
    gluon_tag_end = %Q!</\\s*gluon\\s*>!

    ATTR_PARSE_PATTERN = %r!(#{token})\s*=\s*(#{double_quoted_cdata}|#{single_quoted_cdata})!im
    PARSE_PATTERN = %r!(?:(.*?)(?:(#{gluon_tag_single})|(#{gluon_tag_start})|(#{gluon_tag_end})))|(.+)\z!im

    class << self
      def html_unescape(text)
        text.gsub(/&[a-z]+;/i) {|special|
          case (special)
          when '&lt;'
            '<'
          when '&gt;'
            '>'
          when '&amp;'
            '&'
          when '&quot;'
            '"'
          else
            raise "unknown HTML special: #{special}"
          end
        }
      end

      def parse_attrs(element)
        attrs = {}
        element.scan(ATTR_PARSE_PATTERN) do
          name = $1
          value = $2
          value.sub!(/^["']/, '')
          value.sub!(/["']$/, '')
          attrs[name] = html_unescape(value)
        end
        attrs
      end

      def parse(text)
        parsed_list = []
        text.scan(PARSE_PATTERN) do
          text = $1
          gtag_single = $2
          gtag_start = $3
          gtag_end = $4
          tail = $5

          parsed_list << [ :text, text ] if (text && ! text.empty?)
          parsed_list << [ :gluon_tag_single, gtag_single, parse_attrs(gtag_single) ] if gtag_single
          parsed_list << [ :gluon_tag_start, gtag_start, parse_attrs(gtag_start) ] if gtag_start
          parsed_list << [ :gluon_tag_end, gtag_end ] if gtag_end
          parsed_list << [ :text, tail ] if (tail && ! tail.empty?)

          parsed_list
        end
        parsed_list
      end

      def mkopts(options)
        options.map{|k, v| "#{k.dump} => #{v.dump}" }.join(', ')
      end
      private :mkopts

      def mkind(indent_level)
        '  ' * indent_level
      end
      private :mkind

      def mkcode(parsed_list)
        r = ''
        ind = 0
        for type, src, attrs in parsed_list
          case (type)
          when :text
            r << mkind(ind) << "@out << #{src.dump}\n"
          when :gluon_tag_single
            attrs = attrs.dup
            name = attrs.delete('name') or raise ArgumentError, "not found a name attribute in `#{src}'"
            r << mkind(ind)
            r << "@out << gluon(#{name.dump}"
            r << ', ' << mkopts(attrs) unless attrs.empty?
            r << ")\n"
          when :gluon_tag_start
            attrs = attrs.dup
            name = attrs.delete('name') or raise ArgumentError, "not found a name attribute in `#{src}'"
            r << mkind(ind)
            r << "@out << gluon(#{name.dump}"
            r << ', ' << mkopts(attrs) unless attrs.empty?
            r << ") {\n"
            ind += 1
          when :gluon_tag_end
            ind -= 1
            r << mkind(ind) << "}\n"
          else
            raise "unknown parsed type: #{type}"
          end
        end
        r
      end

      def compile(template_path)
        mkcode(parse(IO.read(template_path)))
      end

      def evaluate(compiled_view, filename='__evaluate__')
        context = Class.new(Context)
        context.class_eval("def call\n#{compiled_view}\nend", filename, 0)
        context
      end
    end

    class Context
      # for ident(1)
      CVS_ID = '$Id$'

      def initialize(po, rs_context)
        @po = po
        @c = rs_context
        @out = ''
      end

      def block_result
        out_save = @out
        @out = ''
        begin
          yield
          result = @out
        ensure
          @out = out_save
        end
        result
      end
      private :block_result

      def gluon(name, attrs={})
        case (name)
        when /^g:/
          command = $'
          case (command)
          when 'content'
            if (block_given?) then
              @po.content{|out|
                out << block_result{ yield }
              }
            else
              @po.content
            end
          else
            raise NameError, "`#{name}' of unknown view command."
          end
        else
          name = name.to_sym

          attrs = attrs.dup
          options = { :attrs => attrs }
          options[:id] = attrs.delete('id') if (attrs.key? 'id')
          options[:class] = attrs.delete('class') if (attrs.key? 'class')

          case (type = @po.find_controller_method_type(name))
          when :value
            @po.value(name)
          when :cond
            @po.cond(name) {
              yield
            }
            ''
          when :foreach
            @po.foreach(name) {
              yield
            }
            ''
          when :link
            if (block_given?) then
              @po.link(name, options) {|out|
                out << block_result{ yield }
              }
            else
              @po.link(name, options)
            end
          when :link_uri
            if (block_given?) then
              @po.link_uri(name, options) {|out|
                out << block_result{ yield }
              }
            else
              @po.link_uri(name, options)
            end
          when :action
            if (block_given?) then
              @po.action(name, options) {|out|
                out << block_result{ yield }
              }
            else
              @po.action(name, options)
            end
          when :frame
            @po.frame(name, options)
          when :frame_uri
            @po.frame_uri(name, options)
          when :import
            if (block_given?) then
              @po.import(name, options) {|out|
                out << block_result{ yield }
              }
            else
              @po.import(name, options)
            end
          when :text
            @po.text(name, options)
          when :password
            @po.password(name, options)
          else
            case (name)
            when :to_s
              @po.value(name)
            else
              if (type) then
                raise NameError, "`#{type}' of unknown controller method type for `#{@po.page_type}\##{name}'."
              else
                raise NameError, "not defined controller method type for `#{@po.page_type}\##{name}'"
              end
            end
          end
        end
      end
    end

    SUFFIX = '.ck'

    def page_render(po)
      @c.view_render(CKView, @c.default_template(self) + SUFFIX, po)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
