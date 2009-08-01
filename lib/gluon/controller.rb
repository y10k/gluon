# -*- coding: utf-8 -*-
# = gluon - simple web application framework
# == license
#   :include:../LICENSE
#

module Gluon
  # = controller and meta-data
  # usage:
  #   class YourController
  #     include Gluon::Controller
  #   end
  #
  module Controller
    # for ident(1)
    CVS_ID = '$Id$'

    # :stopdoc:
    PATH_FILTER = {}
    VIEW_EXPORT = {}
    FORM_EXPORT = {}
    # :startdoc:

    class << self
      def included(module_or_class)
        module_or_class.extend(Component)
        super
      end

      def gluon_path_filter(page_type, path_filter, &block)
        PATH_FILTER[page_type] = {
          :filter => path_filter,
          :block => block
        }
        nil
      end

      def gluon_export(page_type, table, name, type, options)
        name = name.to_sym
        unless (page_type.public_method_defined? name) then
          raise NoMethodError, "not defineid method `#{name}' of `#{page_type}'"
        end
        table[page_type] = {} unless (table.key? name)
        table[page_type][name] = { :type => type, :options => options }
        nil
      end
      private :gluon_export

      def gluon_export_params(page_type, table, name, params={})
        name = name.to_sym
        table[page_type][name].update(params)
        nil
      end
      private :gluon_export_params

      def gluon_view_export(page_type, name, type, options)
        gluon_export(page_type, VIEW_EXPORT, name, type, options)
      end

      def gluon_form_export(page_type, name, type, options)
        gluon_export(page_type, VIEW_EXPORT, name, type, options)
        gluon_export(page_type, FORM_EXPORT, name, type, options)
      end

      def gluon_form_params(page_type, name, params={})
        gluon_export_params(page_type, VIEW_EXPORT, name, params)
        gluon_export_params(page_type, FORM_EXPORT, name, params)
      end

      def find_path_filter(page_type)
        entry = PATH_FILTER[page_type] and return entry[:filter]
      end

      def find_path_block(page_type)
        entry = PATH_FILTER[page_type] and return entry[:block]
      end

      def find_export(table, page_type)
        export = {}
        for module_or_class in page_type.ancestors
          if (table.key? module_or_class) then
            export.update(table[module_or_class])
          end
        end

        export
      end
      private :find_export

      def find_view_export(page_type)
        find_export(VIEW_EXPORT, page_type)
      end

      def find_form_export(page_type)
        find_export(FORM_EXPORT, page_type)
      end

      def set_form_params(controller, req, prefix='')
        form_export = find_form_export(controller.class)
        for name, form_entry in form_export
          case (form_entry[:type])
          when :foreach
            controller.__send__(name).each_with_index do |c, i|
              set_form_params(c, req, "#{prefix}#{name}[#{i}].")
            end
          when :import
            c = controller.__send__(name)
            set_form_params(c, req, "#{prefix}#{name}.")
          when :text, :passwd, :hidden, :textarea
            if (value = req["#{prefix}#{name}"]) then
              controller.__send__(form_entry[:writer], value)
            end
          when :checkbox
            if (req["#{prefix}#{name}:checkbox"] == 'submit') then
              if (req["#{prefix}#{name}"]) then
                controller.__send__(form_entry[:writer], true)
              else
                controller.__send__(form_entry[:writer], false)
              end
            end
          when :radio, :select
            if (value = req["#{prefix}#{name}"]) then
              case (value)
              when Array
                values = value
              else
                values = [ value ]
              end

              case (form_entry[:options][:list])
              when Array
                list = form_entry[:options][:list]
              when Symbol
                list = controller.__send__(form_entry[:options][:list])
              else
                raise "invalid list value: #{form_entry[:options][:list]}"
              end

              values.each do |i|
                unless (list.include? i) then
                  raise "unexpected value for #{prefix}#{name}: #{i}"
                end
              end

              if (form_entry[:options][:multiple]) then
                controller.__send__(form_entry[:writer], values)
              else
                controller.__send__(form_entry[:writer], value)
              end
            end
          end
        end
      end

      def apply_first_action(controller, req, prefix='')
        form_export = find_form_export(controller.class)
        for name, form_entry in form_export
          case (form_entry[:type])
          when :action, :submit
            if (req["#{prefix}#{name}"]) then
              controller.__send__(name)
              return true
            end
          when :foreach
            controller.__send__(name).each_with_index do |c, i|
              apply_first_action(c, req, "#{prefix}#{name}[#{i}].") and return true
            end
          when :import
            c = controller.__send__(name)
            apply_first_action(c, req, "#{prefix}#{name}.") and return true
          end
        end

        false
      end
    end

    attr_writer :r

    def page_around
      yield
    end

    def page_start
    end

    def page_request(*path_args)
      if (@r.equest.get?) then
        request_GET(*path_args)
      elsif (@r.equest.head?) then
        request_HEAD(*path_args)
      elsif (@r.equest.post?) then
        request_POST(*path_args)
      else
        __send__('request_' + @r.equest.request_method, *path_args)
      end
    end

    def request_HEAD(*path_args)
      request_GET(*path_args)
    end

    def page_end
    end
  end

  # = component
  # defined controller syntax.
  #
  # usage:
  #   class YourComponent
  #     extend Gluon::Component
  #   end
  #
  module Component
    def gluon_path_filter(path_filter, &block)
      Controller.gluon_path_filter(self, path_filter, &block)
    end
    private :gluon_path_filter

    def gluon_value(name, options={})
      Controller.gluon_view_export(self, name, :value, options)
    end
    private :gluon_value

    def gluon_value_reader(name, options={})
      class_eval{ attr_reader(name) } # why is class_eval necessary?
      gluon_value(name, options)
    end
    private :gluon_value_reader

    def gluon_cond(name, options={})
      Controller.gluon_view_export(self, name, :cond, options)
    end
    private :gluon_cond

    def gluon_cond_reader(name, options={})
      class_eval{ attr_reader(name) } # why is class_eval necessary?
      gluon_cond(name, options)
    end
    private :gluon_cond_reader

    def gluon_foreach(name, options={})
      Controller.gluon_form_export(self, name, :foreach, options)
    end
    private :gluon_foreach

    def gluon_foreach_reader(name, options={})
      class_eval{ attr_reader(name) } # why is class_eval necessary?
      gluon_foreach(name, options)
    end
    private :gluon_foreach_reader

    def gluon_link(name, options={})
      Controller.gluon_view_export(self, name, :link, options)
    end
    private :gluon_link

    def gluon_link_reader(name, options={})
      class_eval{ attr_reader(name) } # why is class_eval necessary?
      gluon_link(name, options)
    end
    private :gluon_link_reader

    def gluon_action(name, options={})
      Controller.gluon_form_export(self, name, :action, options)
    end
    private :gluon_action

    def gluon_frame(name, options={})
      Controller.gluon_view_export(self, name, :frame, options)
    end
    private :gluon_frame

    def gluon_frame_reader(name, options={})
      class_eval{ attr_reader(name) } # why is class_eval necessary?
      gluon_frame(name, options)
    end
    private :gluon_frame_reader

    def gluon_import(name, options={}, &block)
      options = { :block => block }.merge(options)
      Controller.gluon_form_export(self, name, :import, options)
    end
    private :gluon_import

    def gluon_import_reader(name, options={}, &block)
      class_eval{ attr_reader(name) } # why is class_eval necessary?
      gluon_import(name, options, &block)
    end
    private :gluon_import_reader

    def gluon_submit(name, options={})
      Controller.gluon_form_export(self, name, :submit, options)
    end
    private :gluon_submit

    def gluon_text(name, options={})
      Controller.gluon_form_export(self, name, :text, options)
      Controller.gluon_form_params(self, name, :writer => "#{name}=".to_sym)
    end
    private :gluon_text

    def gluon_text_accessor(name, options={})
      class_eval{ attr_accessor(name) } # why is class_eval necessary?
      gluon_text(name, options)
    end
    private :gluon_text_accessor

    def gluon_passwd(name, options={})
      Controller.gluon_form_export(self, name, :passwd, options)
      Controller.gluon_form_params(self, name, :writer => "#{name}=".to_sym)
    end
    private :gluon_passwd

    def gluon_passwd_accessor(name, options={})
      class_eval{ attr_accessor(name) } # why is class_eval necessary?
      gluon_passwd(name, options)
    end
    private :gluon_passwd_accessor

    def gluon_hidden(name, options={})
      Controller.gluon_form_export(self, name, :hidden, options)
      Controller.gluon_form_params(self, name, :writer => "#{name}=".to_sym)
    end
    private :gluon_hidden

    def gluon_hidden_accessor(name, options={})
      class_eval{ attr_accessor(name) } # why is class_eval necessary?
      gluon_hidden(name, options)
    end
    private :gluon_hidden_accessor

    def gluon_checkbox(name, options={})
      Controller.gluon_form_export(self, name, :checkbox, options)
      Controller.gluon_form_params(self, name, :writer => "#{name}=".to_sym)
    end
    private :gluon_checkbox

    def gluon_checkbox_accessor(name, options={})
      class_eval{ attr_accessor(name) } # why is class_eval necessary?
      gluon_checkbox(name, options)
    end
    private :gluon_checkbox_accessor

    def gluon_radio(name, list, options={})
      options = { :list => list }.merge(options)
      Controller.gluon_form_export(self, name, :radio, options)
      Controller.gluon_form_params(self, name, :writer => "#{name}=".to_sym)
    end
    private :gluon_radio

    def gluon_radio_accessor(name, list, options={})
      class_eval{ attr_accessor(name) } # why is class_eval necessary?
      gluon_radio(name, list, options)
    end
    private :gluon_radio_accessor

    def gluon_select(name, list, options={})
      options = { :list => list }.merge(options)
      Controller.gluon_form_export(self, name, :select, options)
      Controller.gluon_form_params(self, name, :writer => "#{name}=".to_sym)
    end
    private :gluon_select

    def gluon_select_accessor(name, list, options={})
      class_eval{ attr_accessor(name) } # why is class_eval necessary?
      gluon_select(name, list, options)
    end
    private :gluon_select_accessor

    def gluon_textarea(name, options={})
      Controller.gluon_form_export(self, name, :textarea, options)
      Controller.gluon_form_params(self, name, :writer => "#{name}=".to_sym)
    end
    private :gluon_textarea

    def gluon_textarea_accessor(name, options={})
      class_eval{ attr_accessor(name) } # why is class_eval necessary?
      gluon_textarea(name, options)
    end
    private :gluon_textarea_accessor

    def page_view
      ERBView
    end

    def page_template
      nil
    end

    def process_view(rs, po)
      rs.view_render(po, page_view, page_template)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
