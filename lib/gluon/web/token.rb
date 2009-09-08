# -*- coding: utf-8 -*-

require 'digest'
require 'gluon/controller'
require 'gluon/validation'

module Gluon
  module Web
    # one time token for defense of form reload.
    class OneTimeToken
      extend Gluon::Component

      def self.page_encoding
        __ENCODING__
      end

      def self.page_template
        File.join(File.dirname(__FILE__), File.basename(__FILE__, '.rb') + '.erb')
      end

      def new_token
        now = Time.now
        id = Digest::MD5.new
        id.update(now.to_s)
        id.update(now.usec.to_s)
        id.update(rand(0).to_s)
        id.update($$.to_s)
        id.update(Dir.getwd)
        id.update(Thread.current.to_s)
        id.hexdigest
      end
      private :new_token

      # recommended to be initialized at Gluon::Controller#page_start hook.
      def initialize(req_res)
        @r = req_res
        @prev_token = nil
        @next_token = new_token
      end

      def token
        @next_token
      end

      def token=(token)
        @prev_token = token
      end

      gluon_hidden :token

      # recommended to be called by Gluon::Validator#one_time_token.
      def valid_token?
        @prev_token && @prev_token == @r.equest.session[:gluon_one_time_token]
      end

      # recommended to be called at Gluon::Controller#page_end hook.
      def next_token
        @r.equest.session[:gluon_one_time_token] = @next_token
        self
      end
    end
  end

  class Validator
    # ex.
    #   validator.one_time_token               # see @one_time_token object.
    #   validator.one_time_token :token_name   # see @token_name object.
    #   validator.one_time_token :error => 'Not reload form.'
    #   validator.one_time_token :token_name, :error => 'Not reload form.'
    #
    def one_time_token(*args)
      case (args.length)
      when 0
        name = :one_time_token
        options = {}
      when 1
        case (args[0])
        when Symbol
          name = args[0]
          options = {}
        when Hash
          name = :one_time_token
          options = args[0]
        else
          raise ArgumentError, 'need for token name symbol or hash options.'
        end
      when 2
        name, options = args
      else
        raise ArgumentError, "wrong number of arguments (#{args.length} for 2)"
      end

      token = @c.__send__(name)
      error_message = options[:error] || 'Not reload form.'
      validate error_message do
        token.valid_token?
      end

      self
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
