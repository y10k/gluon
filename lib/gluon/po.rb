# = gluon - simple web application framework
#
# Author:: $Author$
# Date:: $Date$
# Revision:: $Revision$
#
# == license
#   :include:../LICENSE
#

require 'erb'
require 'forwardable'
require 'gluon/action'
require 'gluon/controller'

module Gluon
  class PresentationObject
    # for ident(1)
    CVS_ID = '$Id$'

    extend Forwardable

    def initialize(controller, rs_context, action, &block)
      @controller = controller
      @c = rs_context
      @action = action
      @parent_block = block
      @stack = []
    end

    def_delegator :@controller, :class, :page_type

    def self.query(params)
      s = ''
      sep = ''
      for name, value_list in params
        unless (value_list.is_a? Array) then
          value_list = [ value_list ]
        end
        for value in value_list
          s << sep
          s << ERB::Util.url_encode(name)
          s << '=' << ERB::Util.url_encode(value) if value
          sep = '&'
        end
      end
      s
    end

    def prefix
      s = @action.prefix.dup
      for prefix, child in @stack
        s << prefix << '.'
      end
      s
    end
    private :prefix

    def find_this(name)
      unless (block_given?) then
        @stack.reverse_each do |prefix, child|
          if (child.respond_to? name) then
            return child
          end
        end
        @controller
      else
        stack_orig = @stack
        @stack = @stack.dup
        begin
          until (@stack.empty?)
            prefix, child = @stack[-1]
            if (child.respond_to? name) then
              return yield
            end
            @stack.pop
          end

          if (@controller.respond_to? name) then
            return yield
          end
        ensure
          @stack = stack_orig
        end

        raise NoMethodError, "undefined method `#{name}' for `#{@controller.class}'"
      end
    end
    private :find_this

    def funcall(name, *args)
      find_this(name).__send__(name, *args)
    end
    private :funcall

    def curr_this
      if (@stack.empty?) then
        @controller
      else
        prefix, child = @stack[-1]
        child
      end
    end
    private :curr_this

    def curr_funcall(name)
      curr_this.__send__(name)
    end
    private :curr_funcall

    alias form_value curr_funcall; private :form_value

    def getopt(key, options, method, search_stack, default=nil)
      if (options.key? key) then
        value = options[key]
        value = funcall(value) if (value.is_a? Symbol)
        value
      elsif (method) then
        if (search_stack) then
          this = find_this(method)
        else
          this = curr_this
        end
        value = Controller.find_advice(this.class, method, key, default)
        case (value)
        when Proc, Method
          value.call
        when UnboundMethod
          value.bind(this).call
        else
          value
        end
      else
        default
      end
    end
    private :getopt

    def find_controller_method_type(method)
      Controller.find_advice(find_this(method).class, method, :type)
    end

    def value(name=:to_s, options={})
      escape = getopt(:escape, options, name, true, true)
      s = funcall(name).to_s
      s = ERB::Util.html_escape(s) if escape
      s
    end

    class NegativeCondition
      def initialize(operand)
        @operand = operand
      end

      attr_reader :operand
    end

    def cond(name, options={})
      if (name.is_a? NegativeCondition) then
        name = name.operand
        negate = true
      else
        negate = (options.key? :negate) ? options[:negate] : false
      end
      unless (negate) then
        if (funcall(name)) then
          yield
        end
      else
        unless (funcall(name)) then
          yield
        end
      end
      nil
    end

    def foreach(name=:to_a, options={})
      i = 0
      curr_funcall(name).each do |child|
        @stack.push [ "#{name}[#{i}]", child ]
        begin
          case (child)
          when Array, Numeric, String, Struct, Symbol, Time
            # skip action for ruby-primitives
          else
            next_prefix_list = @stack.map{|prefix, child| prefix }
            @action.new_action(child, @c, next_prefix_list, prefix()).call_actions
          end
          yield(i)
        ensure
          @stack.pop
          i += 1
        end
      end
      nil
    end

    def mkattr(name, value)
      case (value)
      when TrueClass
        ' ' << name.to_s << '="' << name.to_s << '"'
      when FalseClass
        ''
      else
        ' ' << name.to_s << '="' << ERB::Util.html_escape(value) << '"'
      end
    end
    private :mkattr

    def mkelem_start(name, reserved_attrs, options, method, search_stack)
      elem = "<#{name}"
      used_attr = {}
      for n, v in getopt(:attrs, {}, method, search_stack, {})
        m = n.downcase
        next if (reserved_attrs.key? m)
        elem << mkattr(n, v)
        used_attr[m] = true
      end
      for n, v in options
        next unless (n.is_a? String)        
        m = n.downcase
        next if (reserved_attrs.key? m)
        next if (used_attr.key? m)
        elem << mkattr(n, v)
      end
      elem
    end
    private :mkelem_start

    def mkpath(path, options)
      if (path.empty?) then
        path = '/' 
      else
        path = ERB::Util.html_escape(path)
      end
      path << '?' << PresentationObject.query(options[:query]) if (options.key? :query)
      path << '#' << ERB::Util.html_escape(options[:fragment]) if (options.key? :fragment)
      path
    end
    private :mkpath

    # :stopdoc:
    MKLINK_RESERVED_ATTRS = {
      'href' => true
    }.freeze
    # :startdoc:

    def mklink(href, options, method)
      elem = mkelem_start('a', MKLINK_RESERVED_ATTRS, options, method, true)
      elem << ' href="' << ERB::Util.html_escape(mkpath(href, options)) << '"'
      elem << '>'
      if (block_given?) then
        out = ''
        yield(out)
        elem << out
      elsif (options.key? :text) then
        text = getopt(:text, options, method, true)
        unless (text.is_a? String) then
          raise TypeError, "unknown link text type: #{text.class}"
        end
        elem << ERB::Util.html_escape(text)
      else
        elem << ERB::Util.html_escape(href)
      end
      elem << '</a>'
    end
    private :mklink

    def expand_link_name(name, options)
      if (name.is_a? Symbol) then
        method = name
        name, controller_options = funcall(method)
        if (controller_options) then
          options = controller_options.dup.update(options)
        end
        return name, options, method
      else
        return name, options
      end
    end
    private :expand_link_name

    def expand_path(name, options)
      case (name)
      when Class
        @c.class2path(name, options[:path_info]) or raise "not mounted: #{name}"
      else
        name
      end
    end
    private :expand_path

    def link(name, options={}, &block)
      name, options, method = expand_link_name(name, options)
      path = expand_path(name, options)
      unless (path.is_a? String) then
        raise TypeError, "unknown link name type: #{name.class}"
      end
      mklink(path, options, method, &block)
    end

    def action(name, options={}, &block)
      find_this(name) {
        query = getopt(:query, options, name, true, {}).dup
        query["#{prefix}#{name}()"] = nil
        text = getopt(:text, options, name, true, name.to_s)
        options = options.dup.update(:query => query, :text => text)
        if (page = getopt(:page, options, name, true)) then
          path = expand_path(page, options)
          unless (path.is_a? String) then
            raise TypeError, "unknown action page type: #{path.class}"
          end
        else
          path = @c.req.script_name + @c.req.env['PATH_INFO']
        end
        mklink(path, options, name, &block)
      }
    end

    # :stopdoc:
    MKFRAME_RESERVED_ATTRS = {
      'src' => true
    }.freeze
    # :startdoc:

    def mkframe(src, options, method)
      elem = mkelem_start('frame', MKFRAME_RESERVED_ATTRS, options, method, true)
      elem << ' src="' << ERB::Util.html_escape(mkpath(src, options)) << '"'
      elem << ' />'
    end
    private :mkframe

    def frame(name, options={})
      name, options, method = expand_link_name(name, options)
      src = expand_path(name, options)
      unless (src.is_a? String) then
        raise TypeError, "unknown frame src type: #{name.class}"
      end
      mkframe(src, options, method)
    end

    def import(name, options={}, &block)
      case (name)
      when Symbol
        value = funcall(name)
      else
        value = name
      end

      case (value)
      when Class
        controller = value.new
      else
        controller = value
      end

      case (name)
      when Symbol
        curr_prefix = name.to_s
      else
        curr_prefix = controller.class.to_s
      end

      prefix = prefix() + curr_prefix + '.'
      next_prefix_list = @stack.map{|_prefix, child| _prefix } + [ curr_prefix ]

      action = @action.new_action(controller, @c, next_prefix_list, prefix)
      action.setup.apply([], :import) {
        action.view_render(&block)
      }
    end

    def content
      if (@parent_block) then
        out = ''
        @parent_block.call(out)
        out
      elsif (block_given?) then
        out = ''
        yield(out)
        out
      else
        raise "not defined content at parent controller of `#{@controller}'."
      end
    end

    def make_controller_name(name, options)
      if (options[:direct]) then
        name
      else
        "#{prefix}#{name}"
      end
    end
    private :make_controller_name

    def make_hidden_type(name, type, options)
      %Q'<input type="hidden" name="#{ERB::Util.html_escape(make_controller_name(name, options))}@type" value="#{ERB::Util.html_escape(type)}" />'
    end
    private :make_hidden_type

    def mkattr_controller_name(name, options)
      %Q' name="#{ERB::Util.html_escape(make_controller_name(name, options))}"'
    end
    private :mkattr_controller_name

    # :stopdoc:
    MKINPUT_RESERVED_ATTRS = {
      'type' => true,
      'name' => true,
      'value' => true,
      'checked' => true
    }.freeze
    # :startdoc:

    # :stopdoc:
    NoValue = Object.new.freeze
    # :startdoc:

    def mkinput(type, name, options, method)
      elem = mkelem_start('input', MKINPUT_RESERVED_ATTRS, options, method, false)
      elem << ' type="' << ERB::Util.html_escape(type) << '"'
      elem << mkattr_controller_name(name, options)
      value = getopt(:value, options, method, false, NoValue)
      elem << ' value="' << ERB::Util.html_escape(value) << '"' if (value != NoValue)
      elem << ' checked="checked"' if options[:checked]
      elem << ' />'
    end
    private :mkinput

    def text(name, options={})
      options = options.dup.update(:value => form_value(name))
      mkinput('text', name, options, name)
    end

    def password(name, options={})
      options = options.dup.update(:value => form_value(name))
      mkinput('password', name, options, name)
    end

    def submit(name, options={})
      unless (curr_this.respond_to? name) then
        raise NoMethodError, "undefined method `#{name}' for `#{curr_this.class}'"
      end
      mkinput('submit', "#{name}()", options, name)
    end

    def hidden(name, options={})
      options = options.dup.update(:value => form_value(name))
      mkinput('hidden', name, options, name)
    end

    def checkbox(name, options={})
      options = options.dup
      options[:value] = 'true' unless (options.key? :value)
      options[:checked] = form_value(name) ? true : false
      make_hidden_type(name, 'bool', options) << mkinput('checkbox', name, options, name)
    end

    def radio(name, value, options={})
      if (list = getopt(:list, {}, name, false)) then
        unless (list.include? value) then
          raise ArgumentError, "unexpected value `#{value}' for `#{curr_this.class}\##{name}'"
        end
      end
      unless (value) then
        raise ArgumentError, "not defined value: #{value.inspect}"
      end
      options = options.dup
      options[:value] = value
      options[:checked] = value == form_value(name)
      mkinput('radio', name, options, name)
    end

    # :stopdoc:
    SELECT_RESERVED_ATTRS = {
      'name' => true,
      'multiple' => true
    }.freeze
    # :startdoc:

    def select(name, options={})
      unless (curr_this.respond_to? name) then
        raise NoMethodError, "undefined method `#{name}' for `#{curr_this.class}'"
      end

      list = getopt(:list, options, name, false) or
        raise ArgumentError, "need for list parameter for `#{curr_this.class}\##{name}'"
      multiple = getopt(:multiple, options, name, false, false)

      if (multiple) then
        elem = make_hidden_type(name, 'list', options)
      else
        elem = ''
      end
      elem << mkelem_start('select', SELECT_RESERVED_ATTRS, options, name, false)
      elem << mkattr_controller_name(name, options)
      elem << ' multiple="multiple"' if multiple
      elem << '>'

      selects = form_value(name)
      selects = [ selects ] unless (selects.is_a? Array)
      selected = {}
      for value in selects
        selected[value] = true
      end

      for value, text in list
        text = value unless text
        elem << '<option value="' << ERB::Util.html_escape(value) << '"'
        elem << ' selected="selected"' if selected[value]
        elem << '>'
        elem << ERB::Util.html_escape(text)
        elem << '</option>'
      end

      elem << '</select>'
    end

    # :stopdoc:
    TEXTAREA_RESERVED_ATTRS = {
      'name' => true
    }.freeze
    # :startdoc:

    def textarea(name, options={})
      elem = mkelem_start('textarea', TEXTAREA_RESERVED_ATTRS, options, name, false)
      elem << mkattr_controller_name(name, options)
      elem << '>'
      elem << ERB::Util.html_escape(form_value(name))
      elem << '</textarea>'
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
