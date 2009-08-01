# -*- coding: utf-8 -*-
# = gluon - simple web application framework
# == license
#   :include:../LICENSE
#

require 'erb'
require 'gluon/controller'

module Gluon
  class PresentationObject
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize(controller, rs, template_engine, prefix='', &block)
      @c_stack = [ controller ]
      @r = rs
      @template_engine = template_engine
      @prefix = prefix
      @parent_block = block
      @export = Hash.new{|hash, page_type|
        hash[page_type] = Controller.find_view_export(page_type)
      }
    end

    def template_render(view, encoding, template_path)
      @template_engine.render(self, @r, view, encoding, template_path)
    end

    def content
      v = ''
      if (@parent_block) then
        @parent_block.call(v)
      elsif (block_given?) then
        yield(v)
      else
        raise 'not defined content.'
      end

      v
    end

    def find_controller(name)
      @c_stack.reverse_each do |c|
        if (@export[c.class].key? name) then
          return c
        end
      end

      nil
    end
    private :find_controller

    def gluon(name, value=nil, &block)
      if (c = find_controller(name)) then
        export_entry = @export[c.class][name]
        case (export_entry[:type])
        when :value
          value(c, name, export_entry, &block)
        when :cond
          cond(c, name, export_entry, &block)
        when :foreach
          foreach(c, name, export_entry, &block)
        when :link
          link(c, name, export_entry, &block)
        when :action
          action(c, name, export_entry, &block)
        when :frame
          frame(c, name, export_entry, &block)
        when :import
          import(c, name, export_entry, &block)
        when :submit
          submit(c, name, export_entry, &block)
        when :text
          text(c, name, export_entry, &block)
        when :passwd
          passwd(c, name, export_entry, &block)
        when :hidden
          hidden(c, name, export_entry, &block)
        when :checkbox
          checkbox(c, name, export_entry, &block)
        when :radio
          radio(c, name, value, export_entry, &block)
        when :select
          select(c, name, export_entry, &block)
        when :textarea
          textarea(c, name, export_entry, &block)
        else
          raise "unknown view export type: #{name}"
        end
      else
        raise ArgumentError, "no view export: #{name}"
      end
    end

    def value(c, name, export_entry)
      escape = true             # default
      if (export_entry[:options].key? :escape) then
        escape = export_entry[:options][:escape]
      end
      v = c.__send__(name)
      v = ERB::Util.html_escape(v) if escape

      v
    end
    private :value

    def cond(c, name, export_entry)
      v = ''
      if (c.__send__(name)) then
        yield(v)
      end

      v
    end
    private :cond

    def foreach(c, name, export_entry)
      v = ''
      save_prefix = @prefix
      begin
        c.__send__(name).each_with_index do |child, i|
          @prefix = "#{save_prefix}.#{name}[#{i}]"
          @c_stack.push(child)
          begin
            yield(v)
          ensure
            @c_stack.pop
          end
        end
      ensure
        @prefix = save_prefix
      end

      v
    end
    private :foreach

    def mkpath(c, name)
      path, *args = c.__send__(name)
      if (path.is_a? Class) then
        path = @r.class2path(path, *pargs)
      end
      ERB::Util.html_escape(path)
    end
    private :mkpath

    def mkattrs(c, options)
      v = ''
      if (attrs = options[:attrs]) then
        for name, value in attrs
          if (value.is_a? Symbol) then
            value = c.__send__(value)
          end

          case (value)
          when TrueClass
            v << ' ' << name << '="' << name << '"'
          when FalseClass
            v << ''
          else
            v << ' ' << name << '="' << ERB::Util.html_escape(value) << '"'
          end
        end
      end

      v
    end
    private :mkattrs

    def anchor_content(options, &block)
      if (block_given?) then
        content = ''
        yield(content)
        return content
      end

      if (content = options[:text]) then
        return ERB::Util.html_escape(content)
      end

      nil
    end
    private :anchor_content

    def link(c, name, export_entry, &block)
      v = '<a'
      v << ' href="' << mkpath(c, name) << '"'
      v << mkattrs(c, export_entry[:options])
      if (content = anchor_content(export_entry[:options], &block)) then
        v << '>' << content << '</a>'
      else
        v << ' />'
      end

      v
    end
    private :link

    def action(c, name, export_entry, &block)
      v = '<a'
      v << ' href="' << ERB::Util.html_escape("#{@r.equest.path}?#{@prefix}#{name}") << '"'
      v << mkattrs(c, export_entry[:options])
      if (content = anchor_content(export_entry[:options], &block)) then
        v << '>' << content << '</a>'
      else
        v << ' />'
      end

      v
    end
    private :action

    def frame(c, name, export_entry)
      v = '<frame'
      v << ' src="' << mkpath(c, name) << '"'
      v << mkattrs(c, export_entry[:options])
      v << ' />'
    end
    private :frame

    def import(c, name, export_entry, &block)
      compo = c.__send__(name)
      po = PresentationObject.new(compo, @template_engine, @r, "#{@prefix}#{name}.", &block)
      compo.class.process_view(po)
    end
    private :import

    def mkinput(c, type, name, value, checked, options)
      v = '<input'
      v << ' type="' << ERB::Util.html_escape(type) << '"'
      v << ' name="' << ERB::Util.html_escape("#{@preifx}#{name}") << '"'
      v << ' value="' << ERB::Util.html_escape(value) << '"' if value
      v << ' checked="checked"' if checked
      v << mkattrs(c, options)
      v << ' />'
    end
    private :mkinput

    def getopt(key, options, c, default=nil)
      if (value = options[key]) then
        if (value.is_a? Symbol) then
          value = c.__send_(value)
        end
        return value
      end

      default
    end
    private :getopt

    def submit(c, name, export_entry)
      value = getopt(:value, export_entry[:options], c)
      mkinput(c, 'submit', name, value, false, export_entry[:options])
    end
    private :submit

    def text(c, name, export_entry)
      mkinput(c, 'text', name, c.__send__(name), false, export_entry[:options])
    end
    private :text

    def passwd(c, name, export_entry)
      mkinput(c, 'password', name, c.__send__(name), false, export_entry[:options])
    end
    private :passwd

    def hidden(c, name, export_entry)
      mkinput(c, 'hidden', name, c.__send__(name), false, export_entry[:options])
    end
    private :hidden

    def checkbox(c, name, export_entry)
      v = '<input type="hidden"'
      v << ' name="' << ERB::Util.html_escape("#{@prefix}#{name}:checkbox") << '"'
      v << ' value="submit"'
      v << ' style="display: none"'
      v << ' />'
      value = getopt(:value, export_entry[:options], c)
      v << mkinput(c, 'checkbox', name, value, c.__send__(name), export_entry[:options])
    end
    private :checkbox

    def radio(c, name, value, export_entry)
      list = getopt(:list, export_entry[:options], c) or
        raise "need for `list' option at `#{c.class}\##{name}'"
      unless (list.include? value) then
        raise ArgumentError, "unexpected value `#{value}' for `#{c.class}\##{name}'"
      end
      checked = c.__send__(name) == value
      mkinput(c, 'radio', name, value, checked, export_entry[:options])
    end
    private :radio

    def select(c, name, export_entry)
      list = getopt(:list, export_entry[:options], c) or
        raise "need for `list' option at `#{c.class}\##{name}'"
      multiple = getopt(:multiple, export_entry[:options], c, false)

      v = '<select'
      v << ' name="' << ERB::Util.html_escape("#{@prefix}#{name}") << '"'
      v << ' multiple="multiple"' if multiple
      v << mkattrs(c, export_entry[:options])
      v << '>'

      selected = {}
      item = c.__send__(name)
      if (item.is_a? Array) then
        for i in item
          selected[i] = true
        end
      else
        selected[item] = true
      end

      for value, text in list
        text = value unless text
        v << '<option'
        v << ' value="' << ERB::Util.html_escape(value) << '"'
        v << ' selected="selected"' if selected[value]
        v << '>'
        v << ERB::Util.html_escape(text)
        v << '</option>'
      end

      v << '</select>'
    end
    private :select

    def textarea(c, name, export_entry)
      v = '<textarea'
      v << ' name="' << ERB::Util.html_escape("#{@prefix}#{name}") << '"'
      v << mkattrs(c, export_entry[:options])
      v << '>'
      v << ERB::Util.html_escape(c.__send__(name))
      v << '</textarea>'
    end
    private :textarea
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
