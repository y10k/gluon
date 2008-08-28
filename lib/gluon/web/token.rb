# = gluon - simple web application framework
#
# Author:: $Author$
# Date:: $Date$
# Revision:: $Revision$
#
# == license
#   :include:../LICENSE
#

require 'digest'

module Gluon
  module Web
    module OneTimeToken
      # for ident(1)
      CVS_ID = '$Id$'

      class TokenField
        def new_token
          now = Time.now
          id = Digest::MD5.new
          id.update(now.to_s)
          id.update(now.usec.to_s)
          id.update(rand(0).to_s)
          id.update($$.to_s)
          id.update(CVS_ID)
          id.hexdigest
        end
        private :new_token

        attr_writer :c

        def page_start
          @token = nil
        end

        gluon_accessor :token

        def page_import
          @token = new_token
          @c.session_get[:one_time_token] = @token
        end

        def __default_view__
          File.join(File.dirname(__FILE__), 'token.rhtml')
        end

        def valid?(c)
          if (@token) then
            if (curr_token = c.session_get[:one_time_token]) then
              @token == curr_token
            else
              false
            end
          else
            true
          end
        end
      end

      def initialize(*args)
        super
        @one_time_token = TokenField.new
      end

      gluon_reader :one_time_token

      def one_time_token_valid?
        @one_time_token.valid? @c
      end
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
