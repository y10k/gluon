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
    token = %q!(?:[^'"\s]+)!
    double_quoted_cdata = %q!(?:"[^"]*")!
    single_quoted_cdata = %q!(?:'[^']*')!
    attr = %Q!(?:#{token}\\s*=\\s*(?:#{double_quoted_cdata}|#{single_quoted_cdata}))!
    gluon_tag_single = %Q!(?:<\\s*gluon(?:\s+#{attr})*\\s*/>)!
    gluon_tag_start = %Q!(?:<\\s*gluon(?:\s+#{attr})*\\s*>)!
    gluon_tag_end = %Q!(?:</\\s*gluon\\s*>)!

    ATTR_PARSE_PATTERN = %r!(#{token})\s*=\s*(#{double_quoted_cdata}|#{single_quoted_cdata})!im
    PARSE_PATTERN = %r!(?:(.*)(?:(#{gluon_tag_single})|(#{gluon_tag_start})|(#{gluon_tag_end})))|(.+)\z!im

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
          gluon_single = $2
          gluon_start = $3
          gluon_end = $4
          tail = $5

          parsed_list << [ :text, text ] if text
          parsed_list << [ :gluon_single, gluon_single, parse_attrs(gluon_single) ] if gluon_single
          parsed_list << [ :gluon_start, gluon_start, parse_attrs(gluon_start) ] if gluon_start
          parsed_list << [ :gluon_end, gluon_end ] if gluon_end
          parsed_list << [ :text, tail ] if tail

          parsed_list
        end
      end
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
