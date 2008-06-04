# one time token

require 'thread'

module Gluon
  module Web
    module OneTimeToken
      # for ident(1)
      CVS_ID = '$Id$'

      class TokenField
        def initialize(count)
          count.update_to(self)
        end

        attr_accessor :value

        def __default_view__
          File.join(File.dirname(__FILE__), 'token.rhtml')
        end
      end

      class TokenCounter
        def initialize
          @lock = Mutex.new
          @value = 0
        end

        def value
          @lock.synchronize{ @value }
        end

        def update_to(field)
          @lock.synchronize{ field.value = @value.to_s }
          self
        end

        def succ!(field)
          @lock.synchronize{
            if (field.value.to_i == @value) then
              @value += 1
              field.value = @value.to_s
              self
            else
              nil
            end
          }
        end
      end

      # :stopdoc:
      COUNT = Hash.new{|hash, key|
        hash[key] = TokenCounter.new
      }
      # :startdoc:

      attr_writer :c
      attr_reader :one_time_token

      # template method for storage of counter. a block parameter of
      # <em>count</em> is an instance of TokenCounter class.
      def one_time_token_transaction # :yields: count
        yield(COUNT[self.class])
      end
      private :one_time_token_transaction

      def one_time_token_setup
        one_time_token_transaction{|count|
          @one_time_token = TokenField.new(count)
          @c.logger.debug("#{self}.one_time_token_setup(): (count,field) -> (#{count.value},#{@one_time_token.value})") if @c.logger.debug?
        }
        nil
      end
      private :one_time_token_setup

      def one_time_token_check
        unless (@one_time_token) then
          raise "need for call: #{OneTimeToken}\#one_time_token_setup"
        end

        ret_val = nil
        one_time_token_transaction{|count|
          @c.logger.debug("#{self}.one_time_token_check(): (count,field) -> (#{count.value},#{@one_time_token.value})") if @c.logger.debug?
          if (count.succ!(@one_time_token)) then
            if (@c.logger.debug?) then
              @c.logger.debug("#{self}.one_time_token_check() -> OK")
              @c.logger.debug("#{self}.one_time_token_check(): (count,field) -> (#{count.value},#{@one_time_token.value})")
            end
            ret_val = true
          else
            @c.logger.debug("#{self}.one_time_token_check() -> NG") if @c.logger.debug?
            ret_val = false
          end
        }

        ret_val
      end
      private :one_time_token_check

      def page_check
        one_time_token_check
      end
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
