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

    ATTR_PARSE_PATTERN = %r!(#{token})\s*=\s*(#{double_quoted_cdata}|#{single_quoted_cdata})!im
    ELEM_PARSE_PATTERN = %r!^</?\s*(#{token})!
    PARSE_PATTERN = %r!(?:(.*?)(?:(#{elem_single})|(#{elem_start})|(#{elem_end})))|(.+)\z!im

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
        text.scan(PARSE_PATTERN) do
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
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
