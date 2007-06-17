# presentation object

require 'erb'
require 'forwardable'

module Gluon
  class PresentationObject
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize(page, rs_context, renderer, action, parent_name=nil)
      @page = page
      @c = rs_context
      @renderer = renderer
      @action = action
      @parent_name = parent_name
      @stack = []
    end

    def view_name
      if (@page.respond_to? :view_name) then
        @page.view_name
      else
        @page.class.name.gsub(/::/, '/') + '.rhtml'
      end
    end

    def self.query(params)
      s = ''
      sep = ''
      for name, value in params
        s << sep
        s << ERB::Util.url_encode(name)
        s << '=' << ERB::Util.url_encode(value) if value
        sep = '&'
      end
      s
    end

    def parent_name
      name_list = []
      name_list << @parent_name if @parent_name
      name_list += @stack.map{|n, c| n }
      unless (name_list.empty?) then
        name_list.join('.')
      end
    end
    private :parent_name

    def parent_prefix
      if (parent_name = parent_name()) then
        parent_name + '.'
      else
        ''
      end
    end
    private :parent_prefix

    def getopts(options, default_options)
      for key, value in default_options
        unless (options.key? key) then
          options[key] = value
        end
      end
      options
    end
    private :getopts

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

    def funcall(name, *args)
      @stack.reverse_each do |parent_name, child|
        if (child.respond_to? name) then
          return child.__send__(name, *args)
        end
      end
      @page.__send__(name, *args)
    end
    private :funcall

    def value(name=:to_s, options={})
      getopts(options, :escape => true)
      s = funcall(name).to_s
      s = ERB::Util.html_escape(s) if options[:escape]
      s
    end

    def cond(name, options={})
      getopts(options, :not => false)
      unless (options[:not]) then
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

    def not_cond(name, options={})
      options[:not] = true
      cond(name, options) {
        yield
      }
    end

    def foreach(name, options={})
      funcall(name).each_with_index do |child, i|
        @stack.push [ "#{name}[#{i}]", child ]
        begin
          action = @action.new(child, @c, parent_name)
          action.apply{ yield(i) }
        ensure
          @stack.pop
        end
      end
      nil
    end

    def mkpath(path, options={})
      if (options.key? :query) then
        path + '?' + PresentationObject.query(options[:query])
      else
        path
      end
    end
    private :mkpath

    def mklink(href, options={})
      elem = '<a'
      elem << ' id="' << ERB::Util.html_escape(options[:id]) << '"' if (options.key? :id)
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
          raise "unknown link text type: #{options[:text].class}"
        end
        elem << ERB::Util.html_escape(text)
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
      else
        name
      end
    end
    private :expand_path

    def link(name, options={})
      name, options2 = funcall(name) if (name.kind_of? Symbol)
      path = expand_path(name)
      options = merge_opts(options, options2)
      unless (path.kind_of? String) then
        raise "unknon link name type: #{name.class}"
      end
      mklink(@c.req.script_name + path, options)
    end

    def link_uri(path, options={})
      path, options2 = funcall(path) if (path.kind_of? Symbol)
      options = merge_opts(options, options2)
      unless (path.kind_of? String) then
        raise "unknon link path type: #{path.class}"
      end
      mklink(path, options)
    end

    def action(name, options={})
      options[:query] = {} unless (options.key? :query)
      options[:query]["#{parent_prefix}#{name}()"] = nil
      options[:text] = name.to_s unless (options.key? :text)
      if (page = options[:page]) then
        path = expand_path(page)
        unless (path.kind_of? String) then
          raise "unknown action page type: #{path.class}"
        end
        path = @c.req.env['SCRIPT_NAME'] + path
      else
        path = @c.req.env['SCRIPT_NAME'] + @c.req.env['PATH_INFO']
      end
      mklink(path, options)
    end

    def mkframe(src, options={})
      elem = '<frame'
      elem << ' id="' << ERB::Util.html_escape(options[:id]) << '"' if (options.key? :id)
      elem << ' src="' << ERB::Util.html_escape(mkpath(src, options)) << '"'
      elem << ' name="' << ERB::Util.html_escape(options[:name]) << '"' if (options.key? :name)
      elem << ' />'
    end
    private :mkframe

    def frame(name, options={})
      name, options2 = funcall(name) if (name.kind_of? Symbol)
      src = expand_path(name)
      options = merge_opts(options, options2)
      unless (src.kind_of? String) then
        raise "unknown frame src type: #{name.class}"
      end
      mkframe(@c.req.script_name + src, options)
    end

    def frame_uri(src, options={})
      src, options2 = funcall(src) if (src.kind_of? Symbol)
      options = merge_opts(options, options2)
      unless (src.kind_of? String) then
        raise "unknown frame src type: #{src.class}"
      end
      mkframe(src, options)
    end

    def import(name, options={})
      name = funcall(name) if (name.kind_of? Symbol)
      unless (name.kind_of? Class) then
        raise "unknown import name type: #{name.class}"
      end
      parent_name = parent_name()
      page = name.new
      action = @action.new(page, @c, parent_name)
      po = PresentationObject.new(page, @c, @renderer, action, parent_name)
      context = ERBContext.new(po, @c)

      result = nil
      action.apply{ result = @renderer.render(context) }
      result
    end
  end

  class ERBContext
    # for ident(1)
    CVS_ID = '$Id$'

    extend Forwardable
    include ERB::Util

    def initialize(po, rs_context)
      @po = po
      @c = rs_context
    end

    attr_reader :po
    def_delegator :@c, :req
    def_delegator :@c, :res
    def_delegator :@po, :value
    def_delegator :@po, :cond
    def_delegator :@po, :not_cond
    def_delegator :@po, :foreach
    def_delegator :@po, :link
    def_delegator :@po, :link_uri
    def_delegator :@po, :action
    def_delegator :@po, :frame
    def_delegator :@po, :frame_uri
    def_delegator :@po, :import
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
