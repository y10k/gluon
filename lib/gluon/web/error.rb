# -*- coding: utf-8 -*-

require 'gluon/controller'

module Gluon
  module Web
    # = error message board component
    class ErrorMessages
      extend Component

      def_page_encoding __ENCODING__

      def_page_template File.join(File.dirname(__FILE__),
                                  File.basename(__FILE__, '.rb') + '.erb')

      def initialize(options={})
        @title = (options.key? :title) ? options[:title] : 'ERROR(s)'
        @head_level = options[:head_level] || 2
        @css_class = options[:class] || nil
        @messages = []
      end

      class Message
        extend Component

        def initialize(message)
          @error_message = message
        end

        gluon_value_reader :error_message
      end

      def add(message)
        @messages << Message.new(message)
        self
      end

      alias << add

      gluon_value_reader :title
      gluon_value_reader :head_level
      gluon_value_reader :css_class
      gluon_foreach_reader :messages

      def exist_messages?
        ! @messages.empty?
      end
      gluon_cond :exist_messages?

      def exist_title?
        @title ? true : false
      end
      gluon_cond :exist_title?

      def exist_css_class?
        @css_class ? true : false
      end
      gluon_cond :exist_css_class?
      gluon_cond_not :exist_css_class?

      module AddOn
        extend Gluon::Component

        def error_messages_params
          []
        end

        def __addon_init__
          super                 # for add-on chain.
          args = error_messages_params
          if (@r.logger.debug?) then
            args_log = args.map{|i| i.inspect }.join(',')
            @r.logger.debug("#{self}: __addon_init__ at #{AddOn}(#{args_log}).")
          end
          @errors = ErrorMessages.new(*args)
        end

        gluon_import_reader :errors
      end

      def self.AddOn(*args)
        Module.new{
          include Gluon::Web::ErrorMessages::AddOn
          define_method(:error_messages_params) { args }
        }
      end
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
