# = gluon - simple web application framework
#
# Author:: $Author$
# Date:: $Date$
# Revision:: $Revision$
#
# == license
#   :include:../LICENSE
#

require 'gluon/controller'
require 'gluon/erbview'
require 'gluon/nolog'
require 'gluon/po'

module Gluon
  class Action
    # for ident(1)
    CVS_ID = '$Id$'

    RESERVED_WORDS = {
      'c' => true,
      'c=' => true,
      '__view__' => true,
      '__default_view__' => true,
      '__cache_key__' => true,
      '__if_modified__' => true
    }.freeze

    EMPTY_PARAMS = {
      :params => {}.freeze,
      :used => {}.freeze,
      :branches => {}.freeze
    }.freeze

    EMPTY_FUNCS = {}.freeze

    class << self
      def parse_params(req_params)
        parsed_params = {
          :params => {},
          :used => {},
          :branches => {}
        }
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
            parsed_params[:branches][name] = {
              :params => {},
              :used => {},
              :branches => {}
            }
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
      elsif (name =~ /^page_/) then
        false
      else
        Controller.find_exported_method(this.class, name)
      end
    end

    def set_params
      set_parameters(@controller, @params)
      self
    end

    def set_parameters(this, params)
      return if (this.kind_of? Module)
      for name, value in params[:params]
        next if params[:used][name]
        writer = "#{name}="
        if (advices = export? writer, this) then
          unless (advices[:accessor]) then
            raise "not an accessor: #{this}.#{writer}"
          end
          @logger.debug("#{this}.#{name} = #{value}") if @logger.debug?
          this.__send__(writer, value)
        else
          raise NoMethodError, "undefined method `#{writer}' for `#{this.class}'"
        end
        params[:used][name] = true
      end
      for name, nested_params in params[:branches]
        case (name)
        when /\[\d+\]$/
          i = $&[1..-2].to_i
          name = $`
          if (name == 'to_a' || (advices = export? name, this)) then
            if (advices && ! advices[:accessor]) then
              raise "not an accessor: #{this}.#{name}"
            end
            ary = this.__send__(name)
            set_parameters(ary[i], nested_params)
          else
            raise NoMethodError, "undefined method `#{name}' for `#{this.class}'"
          end
        else
          if (advices = export? name, this) then
            unless (advices[:accessor]) then
              raise "not an accessor: #{this}.#{name}"
            end
            next_this = this.__send__(name)
            if (! next_this.nil?) then
              set_parameters(this.__send__(name), nested_params)
            else
              # skip not-initialized attributes
            end
          else
            raise NoMethodError, "undefined method `#{name}' for `#{this.class}'"
          end
        end
      end
    end
    private :set_parameters

    def call_actions
      if (funcs = @funcs[@prefix]) then
        funcs.each_key do |name|
          if (advices = export? name) then
            if (advices[:accessor]) then
              raise "accessor is not action: #{@controller}.#{name}"
            end
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

    def page_around_hook
      r = nil
      if (@controller.respond_to? :page_around_hook) then
        @logger.debug("#{@controller}.page_around_hook() start") if @logger.debug?
        @controller.page_around_hook{
          r = yield
        }
        @logger.debug("#{@controller}.page_around_hook() end") if @logger.debug?
      else
        r = yield
      end
      r
    end
    private :page_around_hook

    def page_method(name, path_args)
      @logger.debug("#{@controller}.#{name}(#{path_args.join(',')})") if @logger.debug?
      @controller.__send__(name, *path_args)
    end
    private :page_method

    def page_http_request(path_args)
      if (@c.req.request_method !~ /^[A-Z]+$/) then
        raise "unknown request-method: #{@c.req.request_method}"
      end
      name = "page_#{@c.req.request_method.downcase}"
      case (name)
      when 'page_head'
        if (@controller.respond_to? :page_head) then
          page_method(:page_head, path_args)
        else
          page_method(:page_get, path_args)
        end
      when 'page_around_hook', 'page_start', 'page_end'
        raise "invalid request-method: #{@c.req.request_method}"
      else
        page_method(name, path_args)
      end
      nil
    end
    private :page_http_request

    def apply(path_args=[])
      @logger.debug("#{Action}#apply() for #{@controller} - start") if @logger.debug?
      @c.validation = nil
      r = nil
      page_around_hook{
        if (@controller.respond_to? :page_start) then
          @logger.debug("#{@controller}.page_start()") if @logger.debug?
          @controller.page_start
        end
        set_params
        begin
          if (path_args == :import) then
            page_method(:page_import, [])
          else
            page_http_request(path_args)
          end
          @logger.debug("validation for #{@controller} => #{@c.validation.inspect}") if @logger.debug?
          if (@funcs.key? @prefix) then
            if (@c.validation.nil?) then
              raise "unchecked validation at #{@controller}."
            end
            call_actions if @c.validation
          end
          r = yield
        ensure
          if (@controller.respond_to? :page_end) then
            @logger.debug("#{@controller}.page_end()") if @logger.debug?
            @controller.page_end
          end
        end
      }
      @logger.debug("#{Action}#apply() for #{@controller} - end") if @logger.debug?
      r
    end

    def view_render
      po = PresentationObject.new(@controller, @c, self)
      @controller.extend(ERBView) unless (@controller.respond_to? :page_render)
      @logger.debug("#{@controller}.page_render(#{po})") if @logger.debug?
      @controller.page_render(po)
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
