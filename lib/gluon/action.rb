# action

require 'gluon/nolog'

module Gluon
  class Action
    # for ident(1)
    CVS_ID = '$Id$'

    RESERVED_WORDS = {
      'c' => true,
      'c=' => true,
      'page_hook' => true,
      'page_check' => true,
      'page_start' => true,
      'page_end' => true,
      '__view__' => true,
      '__default_view__' => true,
      '__cache_key__' => true,
      '__if_modified__' => true,
      '__export__' => true
    }.freeze

    EMPTY_PARAMS = {
      :params => {}.freeze,
      :branches => {}.freeze
    }.freeze

    EMPTY_FUNCS = {}.freeze

    class << self
      def parse_params(req_params)
        parsed_params = { :params => {}, :branches => {} }
        for key, value in req_params
          if (key =~ /@/) then
            name = $`
            type = req_params[key]
            unless (req_params.key? name) then
              case (type)
              when 'bool'
                parse_parameter(name.split(/\./), false, parsed_params, name, req_params)
              when 'list'
                parse_parameter(name.split(/\./), [], parsed_params, name, req_params)
              end
            end
          else
            names = key.split(/\./)
            parse_parameter(names, value, parsed_params, key, req_params)
          end
        end
        parsed_params
      end

      def parse_parameter(names, value, parsed_params, key, req_params)
        case (names.length)
        when 0
          # nothing to do.
        when 1
          name = names[0]
          return if (name =~ /[\]\)]$/)
          type = req_params["#{key}@type"] || 'scalar'
          case (type)
          when 'scalar'
            parsed_params[:params][name], = value
          when 'list'
            case (value)
            when Array
              parsed_params[:params][name] = value
            else
              parsed_params[:params][name] = [ value ]
            end
          when 'bool'
            case (value)
            when true, false
              parsed_params[:params][name] = value
            else
              parsed_params[:params][name] = true
            end
          else
            raise "unknown type of #{key}: #{type}"
          end
        else # > 0
          name = names.shift
          unless (parsed_params[:branches].key? name) then
            parsed_params[:branches][name] = { :params => {}, :branches => {} } 
          end
          parse_parameter(names, value, parsed_params[:branches][name], key, req_params)
        end
      end
      private :parse_parameter

      def parse_funcs(req_params)
        parsed_funcs = {}
        for key, value in req_params
          key =~ /\(\)$/ or next
          names = $`.split(/\./)
          name = names.pop
          if (names.empty?) then
            path = ''
          else
            path = names.join('.') + '.'
          end
          parsed_funcs[path] = {} unless (parsed_funcs.key? path)
          parsed_funcs[path][name] = true
        end
        parsed_funcs
      end

      def parse(req_params)
        return parse_params(req_params), parse_funcs(req_params)
      end
    end

    def initialize(controller, rs_context, params, funcs, prefix='')
      @controller = controller
      @c = rs_context
      @params = params
      @funcs = funcs
      @prefix = prefix
      @object = Object.new
      @logger = NoLogger.instance
    end

    attr_reader :prefix
    attr_writer :logger

    def export?(name, this=@controller)
      if (RESERVED_WORDS.key? name) then
        false
      elsif (this.respond_to? :__export__) then
        this.__export__(name)
      elsif (@object.respond_to? name) then
        false
      else
        if (this.respond_to? name, false) then
          true
        elsif (this.respond_to? name, true) then # deny for private method
          false
        else
          true
        end
      end
    end

    def set_params
      set_parameters(@controller, @params)
      self
    end

    def set_parameters(this, params)
      return if (this.kind_of? Module)
      for name, value in params[:params]
        writer = "#{name}="
        if (export? writer, this) then
          if (this.respond_to? writer) then
            @logger.debug("#{this}.#{name} = #{value}") if @logger.debug?
            this.__send__(writer, value)
          end
        end
      end
      for name, nested_params in params[:branches]
        case (name)
        when /\[\d+\]$/
          i = $&[1..-2].to_i
          name = $`
          if (name == 'to_a' || (export? name, this)) then
            if (this.respond_to? name) then
              ary = this.__send__(name)
              set_parameters(ary[i], nested_params)
            end
          end
        else
          if (export? name, this) then
            if (this.respond_to? name) then
              set_parameters(this.__send__(name), nested_params)
            end
          end
        end
      end
    end
    private :set_parameters

    def call_actions
      if (funcs = @funcs[@prefix]) then
        funcs.each_key do |name|
          if (export? name) then
            @logger.debug("#{@controller}.#{name}()") if @logger.debug?
            @controller.__send__(name)
          else
            raise NoMethodError, "undefined method `#{name}' for `#{@controller.class}'"
          end
        end
      end
      self
    end

    def setup
      if (@controller.respond_to? :c=) then
        @logger.debug("#{@controller}.c = #{@c}") if @logger.debug?
        @controller.c = @c
      end
      self
    end

    def cache_key
      if (@controller.respond_to? :__cache_key__) then
        @controller.__cache_key__
      end
    end

    def modified?(cache_tag)
      if (@controller.respond_to? :__if_modified__) then
        @controller.__if_modified__(cache_tag)
      else
        true
      end
    end

    def page_hook
      r = nil
      if (@controller.respond_to? :page_hook) then
        @logger.debug("#{@controller}.page_hook() start") if @logger.debug?
        @controller.page_hook{
          r = yield
        }
        @logger.debug("#{@controller}.page_hook() end") if @logger.debug?
      else
        r = yield
      end
      r
    end
    private :page_hook

    def page_check
      if (@controller.respond_to? :page_check) then
        @logger.debug("#{@controller}.page_check()") if @logger.debug?
        if (@controller.page_check) then
          @logger.debug("#{@controller}.page_check() -> OK") if @logger.debug?
          return true
        else
          @logger.debug("#{@controller}.page_check() -> NG") if @logger.debug?
          return false
        end
      end

      true
    end
    private :page_check

    def apply(renderer, no_set_params=false)
      @logger.debug("#{self}.apply() - start")
      r = nil
      page_hook{
        if (@controller.respond_to? :page_start) then
          @logger.debug("#{@controller}.page_start()") if @logger.debug?
          @controller.page_start
        end
        begin
          set_params unless no_set_params
          if (@funcs.key? @prefix) then
            call_actions if page_check
          end
          r = renderer.call(@controller, @c, self)
        ensure
          if (@controller.respond_to? :page_end) then
            @logger.debug("#{@controller}.page_end()") if @logger.debug?
            @controller.page_end
          end
        end
      }
      @logger.debug("#{self}.apply() - end")
      r
    end

    def new_action(controller, rs_context, next_prefix_list, prefix)
      next_params = @params
      for next_name in next_prefix_list
        unless (next_params[:branches].key? next_name) then
          next_params = EMPTY_PARAMS
          break
        end
        next_params = next_params[:branches][next_name]
      end

      action = Action.new(controller, rs_context, next_params, @funcs, prefix)
      action.logger = @logger

      action
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
