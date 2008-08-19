# = gluon - simple web application framework
#
# Author:: $Author$
# Date:: $Date$
# Revision:: $Revision$
#
# == license
#   :include:../../LICENSE
#

module Gluon
  module Web
    # = error messages utility
    class ErrorMessages
      # for ident(1)
      CVS_ID = '$Id$'

      extend Forwardable

      def initialize(options={})
        @title = (options.key? :title) ? options[:title] : 'ERROR(s)'
        @head_level = options[:head_level] || 2
        @css_class = options[:class] || nil
        @messages = []
      end

      def add(message)
        @messages << message
        self
      end

      alias << add

      attr_reader :title
      attr_reader :head_level
      attr_reader :css_class
      attr_reader :messages

      def has_messages?
        ! @messages.empty?
      end

      def has_title?
        @title ? true : false
      end

      def has_class?
        @css_class ? true : false
      end

      def __export__(name)
        false
      end

      def __default_view__
        File.join(File.dirname(__FILE__), 'error.rhtml')
      end
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
