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

    def initialize(controller, rs_context, action)
      @controller = controller
      @c = rs_context
      @action = action
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

    def mkelem_start(name, reserved_attrs, options, method, search_stack)
      elem = "<#{name}"
      for name in [ :id, :class ]
        if (value = getopt(name, options, method, search_stack)) then
          elem << ' ' << name.to_s << '="' << ERB::Util.html_escape(value) << '"'
        end
      end
      if (options.key? :attrs) then
        for name, value in options[:attrs]
          unless (name.is_a? String) then
            raise TypeError, "not a String: #{name.inspect}"
          end
          n = name.downcase
          next if (reserved_attrs.key? n)
          next if (n == 'id')
          next if (n == 'class')
          elem << ' ' << name << '="' << ERB::Util.html_escape(value) << '"'
        end
      end
      elem
    end
    private :mkelem_start

    def mkpath(path, options)
      path = path.dup
      path << ERB::Util.html_escape(options[:path_info]) if (options.key? :path_info)
      path = '/' if path.empty?
      path << '?' << PresentationObject.query(options[:query]) if (options.key? :query)
      path << '#' << ERB::Util.html_escape(options[:fragment]) if (options.key? :fragment)
      path
    end
    private :mkpath

    # :stopdoc:
    MKLINK_RESERVED_ATTRS = {
      'href' => true,
      'target' => true
    }.freeze
    # :startdoc:

    def mklink(href, options, method)
      elem = mkelem_start('a', MKLINK_RESERVED_ATTRS, options, method, true)
      elem << ' href="' << ERB::Util.html_escape(mkpath(href, options)) << '"'
      elem << ' target="' << ERB::Util.html_escape(options[:target]) << '"' if (options.key? :target)
      elem << '>'
      if (options.key? :text) then
        case (options[:text])
        when Symbol
          text = funcall(options[:text])
        when String
          text = options[:text]
        else
          raise TypeError, "unknown link text type: #{options[:text].class}"
        end
        elem << ERB::Util.html_escape(text)
      elsif (block_given?) then
        out = ''
        yield(out)
        elem << out
      else
        elem << ERB::Util.html_escape(href)
      end
      elem << '</a>'
    end
    private :mklink

    def expand_path(name)
      case (name)
      when Class
        @c.class2path(name) or raise "not mounted: #{name}"
      when String
        @c.req.script_name + name
      else
        name
      end
    end
    private :expand_path

    def merge_opts(*opts_list)
      opts_list = opts_list.compact
      if (opts_list.length == 1) then
        return opts_list[0]
      end

      options = {}
      opts_list.reverse_each do |o|
        options.update(o)
      end

      query = nil
      opts_list.map{|opts| opts[:query] }.compact.reverse_each do |q|
        query = {} unless query
        query.update(q)
      end
      options[:query] = query if query

      options
    end
    private :merge_opts

    def expand_link_name(name, options)
      if (name.is_a? Symbol) then
        method = name
        name, options2 = funcall(method)
        return name, merge_opts(options, options2), method
      else
        return name, options
      end
    end
    private :expand_link_name

    def link(name, options={}, &block)
      name, options, method = expand_link_name(name, options)
      path = expand_path(name)
      unless (path.is_a? String) then
        raise TypeError, "unknown link name type: #{name.class}"
      end
      mklink(path, options, method, &block)
    end

    def link_uri(path, options={}, &block)
      path, options, method = expand_link_name(path, options)
      unless (path.is_a? String) then
        raise TypeError, "unknon link path type: #{path.class}"
      end
      mklink(path, options, method, &block)
    end

    def action(name, options={}, &block)
      find_this(name) {
        options[:query] = {} unless (options.key? :query)
        options[:query]["#{prefix}#{name}()"] = nil
        options[:text] = name.to_s unless (options.key? :text)
        if (page = options[:page]) then
          path = expand_path(page)
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
      'src' => true,
      'name' => true
    }.freeze
    # :startdoc:

    def mkframe(src, options, method)
      elem = mkelem_start('frame', MKFRAME_RESERVED_ATTRS, options, method, true)
      elem << ' src="' << ERB::Util.html_escape(mkpath(src, options)) << '"'
      elem << ' name="' << ERB::Util.html_escape(options[:name]) << '"' if (options.key? :name)
      elem << ' />'
    end
    private :mkframe

    def frame(name, options={})
      name, options, method = expand_link_name(name, options)
      src = expand_path(name)
      unless (src.is_a? String) then
        raise TypeError, "unknown frame src type: #{name.class}"
      end
      mkframe(src, options, method)
    end

    def frame_uri(src, options={})
      src, options, method = expand_link_name(src, options)
      unless (src.is_a? String) then
        raise TypeError, "unknown frame src type: #{src.class}"
      end
      mkframe(src, options, method)
    end

    def import(name, options={})
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
      action.setup.apply(:import) {
        action.view_render
      }
    end

    def mkattr_bool(key, options, method)
      if (value = getopt(key, options, method, false)) then
        " #{key}=\"#{key}\""
      else
        ''
      end
    end
    private :mkattr_bool

    def mkattr_disabled(options, method)
      mkattr_bool(:disabled, options, method)
    end
    private :mkattr_disabled

    def mkattr_readonly(options, method)
      mkattr_bool(:readonly, options, method)
    end
    private :mkattr_readonly

    def mkattr_string(key, options, method)
      if (value = getopt(key, options, method, false)) then
        " #{key}=\"#{ERB::Util.html_escape(value)}\""
      else
        ''
      end
    end
    private :mkattr_string

    def mkattr_size(options, method)
      mkattr_string(:size, options, method)
    end
    private :mkattr_size

    def mkattr_maxlength(options, method)
      mkattr_string(:maxlength, options, method)
    end
    private :mkattr_maxlength

    def mkattr_rows(options, method)
      mkattr_string(:rows, options, method)
    end
    private :mkattr_rows

    def mkattr_cols(options, method)
      mkattr_string(:cols, options, method)
    end
    private :mkattr_cols

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
      'size' => true,
      'maxlength' => true,
      'checked' => true,
      'disabled' => true,
      'readonly' => true
    }.freeze
    # :startdoc:

    def mkinput(type, name, options, method)
      elem = mkelem_start('input', MKINPUT_RESERVED_ATTRS, options, method, false)
      elem << ' type="' << ERB::Util.html_escape(type) << '"'
      elem << mkattr_controller_name(name, options)
      elem << ' value="' << ERB::Util.html_escape(options[:value]) << '"' if (options.key? :value)
      elem << ' checked="checked"' if options[:checked]
      elem << mkattr_size(options, method)
      elem << mkattr_maxlength(options, method)
      elem << mkattr_disabled(options, method)
      elem << mkattr_readonly(options, method)
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
      options = options.dup
      options[:value] = value
      options[:checked] = value == form_value(name)
      mkinput('radio', name, options, name)
    end

    # :stopdoc:
    SELECT_RESERVED_ATTRS = {
      'name' => true,
      'size' => true,
      'multiple' => true,
      'disabled' => true
    }.freeze
    # :startdoc:

    def select(name, list, options={})
      if (options[:multiple]) then
        elem = make_hidden_type(name, 'list', options)
      else
        elem = ''
      end

      elem << mkelem_start('select', SELECT_RESERVED_ATTRS, options, name, false)
      elem << mkattr_controller_name(name, options)
      elem << ' multiple="multiple"' if options[:multiple]
      elem << mkattr_size(options, name)
      elem << mkattr_disabled(options, name)
      elem << '>'

      list = funcall(list) if (list.is_a? Symbol)
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
      'name' => true,
      'rows' => true,
      'cols' => true,
      'disabled' => true,
      'readonly' => true
    }.freeze
    # :startdoc:

    def textarea(name, options={})
      elem = mkelem_start('textarea', TEXTAREA_RESERVED_ATTRS, options, name, false)
      elem << mkattr_controller_name(name, options)
      elem << mkattr_rows(options, name)
      elem << mkattr_cols(options, name)
      elem << mkattr_disabled(options, name)
      elem << mkattr_readonly(options, name)
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
