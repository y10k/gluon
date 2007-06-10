# presentation object

require 'erb'
require 'forwardable'
require 'gluon/action'

module Gluon
  class PresentationObject
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize(page, req, res, renderer, parent_name=nil)
      @parent_name = parent_name
      @renderer = renderer
      @page = page
      @req = req
      @res = res
      @stack = []
    end

    def view_name
      if (@page.respond_to? :view_name) then
        @page.view_name
      else
        @page.class.name.gsub(/::/, '/') + '.rhtml'
      end
    end

    def parent_name
      name_list = []
      name_list << @parent_name if @parent_name
      name_list += @stack.map{|n, c| n }
      name_list.join('.')
    end
    private :parent_name

    def getopts(options, default_options)
      for key, value in default_options
        unless (options.key? key) then
          options[key] = value
        end
      end
      options
    end
    private :getopts

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
          action = Action.new(child, @req, @res, parent_name)
          action.apply{ yield(i) }
        ensure
          @stack.pop
        end
      end
      nil
    end

    def link(prefix, name, options={})
      case (name)
      when Symbol
        href = prefix + funcall(name)
      when String
        href = prefix + name
      else
        raise "unknon link name type: #{name.class}"
      end

      elem = '<a'
      elem << ' id="' << ERB::Util.html_escape(options[:id]) << '"' if (options.key? :id)
      elem << ' href="' << ERB::Util.html_escape(href) << '"'
      elem << ' target="' << ERB::Util.html_escape(options[:target]) << '"' if (options.key? :target)
      elem << '>'
      if (options.key? :text) then
        case (options[:text])
        when Symbol
          text = funcall(options[:text])
        when String
          text = options[:text]
        else
          raise "unknown link text type: #{name.class}"
        end
        elem << ERB::Util.html_escape(text)
      else
        elem << ERB::Util.html_escape(href)
      end
      elem << '</a>'
    end
    private :link

    def link_uri(name, options={})
      link('', name, options)
    end

    def link_path(name, options={})
      link(@req.script_name, name, options)
    end

    def frame(prefix, name, options={})
      case (name)
      when Symbol
        src = prefix + funcall(name)
      when String
        src = prefix + name
      else
        raise "unknown frame src type: #{src.class}"
      end

      elem = '<frame'
      elem << ' id="' << ERB::Util.html_escape(options[:id]) << '"' if (options.key? :id)
      elem << ' src="' << ERB::Util.html_escape(src) << '"'
      elem << ' name="' << ERB::Util.html_escape(options[:name]) << '"' if (options.key? :name)
      elem << ' />'
    end
    private :frame

    def frame_uri(name, options={})
      frame('', name, options)
    end

    def frame_path(name, options={})
      frame(@req.script_name, name, options)
    end

    def import(name, options={})
      case (name)
      when Symbol
        page_type = funcall(name)
      when Class
        page_type = name
      else
        raise "unknown import name type: #{name.class}"
      end

      parent_name = parent_name()
      page = page_type.new
      action = Action.new(page, @req, @res, parent_name)
      po = PresentationObject.new(page, @req, @res, @renderer, parent_name)
      context = ERBContext.new(po, @req, @res)

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

    class << self
      def context_binding(_)
        _.instance_eval{ binding }
      end

      def render(context, eruby_script)
        b = context_binding(context)
        erb = ERB.new(eruby_script)
        erb.result(b)
      end
    end

    def initialize(po, req, res)
      @po = po
      @req = req
      @res = res
    end

    attr_reader :po
    attr_reader :req
    attr_reader :res

    def_delegator :@po, :value
    def_delegator :@po, :cond
    def_delegator :@po, :not_cond
    def_delegator :@po, :foreach
    def_delegator :@po, :link_uri
    def_delegator :@po, :link_path
    def_delegator :@po, :frame_uri
    def_delegator :@po, :frame_path
    def_delegator :@po, :import
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
