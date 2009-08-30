# -*- coding: utf-8 -*-
# = gluon - simple web application framework
# == license
#   :include:../LICENSE
#

require 'gluon/erbview'

class Module
  def gluon_metainfo
    @gluon_metainfo ||= {
      :path_filter => nil,
      :view_export => {},
      :form_export => {},
      :action_export => {}
    }
  end
end

module Gluon
  # = easy memoization
  module Memoization
    def memoize(name, cache={})
      cache_var = "@__memoize_cache_#{name}"
      instance_variable_set(cache_var, cache)
      instance_eval(<<-EOF, "#{__FILE__}:memoize(#{name})", __LINE__ + 1)
        class << self
          alias __no_memoize_#{name} #{name}

          def #{name}(*args, &block)
            if (#{cache_var}.key? args) then
              #{cache_var}[args]
            else
              #{cache_var}[args] = __no_memoize_#{name}(*args, &block)
            end
          end
        end
      EOF

      nil
    end
  end

  # = controller and meta-data
  # usage:
  #   class YourController
  #     include Gluon::Controller
  #   end
  #
  module Controller
    extend Memoization

    class << self
      def included(module_or_class)
        module_or_class.extend(Component)
        super
      end

      def gluon_path_filter(page_type, path_filter, &block)
        page_type.gluon_metainfo[:path_filter] = {
          :filter => path_filter,
          :block => block
        }
        nil
      end

      def gluon_export(page_type, export_type, name, type, options)
        name = name.to_sym
        unless (page_type.public_method_defined? name) then
          raise NoMethodError, "not defineid method `#{name}' of `#{page_type}'"
        end
        page_type.gluon_metainfo[export_type][name] = { :type => type, :options => options }
        nil
      end
      private :gluon_export

      def gluon_view_export(page_type, name, type, options)
        gluon_export(page_type, :view_export, name, type, options)
      end

      def gluon_form_export(page_type, name, type, options)
        gluon_export(page_type, :view_export, name, type, options)
        gluon_export(page_type, :form_export, name, type, options)
      end

      # action is additional export.
      def gluon_action_export(page_type, name, type, options)
        gluon_export(page_type, :action_export, name, type, options)
      end

      def gluon_form_params(page_type, name, params={})
        page_type.gluon_metainfo[:form_export][name].update(params)
      end

      def find_path_filter_entry(page_type)
        page_type.ancestors.each do |module_or_class|
          if (entry = module_or_class.gluon_metainfo[:path_filter]) then
            return entry
          end
        end

        nil
      end
      private :find_path_filter_entry

      def find_path_filter(page_type)
        entry = find_path_filter_entry(page_type) and return entry[:filter]
      end

      def find_path_block(page_type)
        entry = find_path_filter_entry(page_type) and return entry[:block]
      end

      def find_export(export_type, page_type)
        export = {}
        page_type.ancestors.reverse_each do |module_or_class|
          export.update(module_or_class.gluon_metainfo[export_type])
        end

        export
      end
      private :find_export

      def find_view_export(page_type)
        find_export(:view_export, page_type)
      end

      def find_form_export(page_type)
        find_export(:form_export, page_type)
      end

      def find_action_export(page_type)
        find_export(:action_export, page_type)
      end

      def set_form_params(controller, req_params, prefix='')
        form_export = find_form_export(controller.class)
        for name, form_entry in form_export
          case (form_entry[:type])
          when :foreach
            if (list = controller.__send__(name)) then
              list.each_with_index do |c, i|
                set_form_params(c, req_params, "#{prefix}#{name}(#{i}).")
              end
            end
          when :import
            if (c = controller.__send__(name)) then
              set_form_params(c, req_params, "#{prefix}#{name}.")
            end
          when :text, :passwd, :hidden, :textarea
            if (value = req_params["#{prefix}#{name}"]) then
              controller.__send__(form_entry[:writer], value)
            end
          when :checkbox
            if (req_params["#{prefix}#{name}:checkbox"] == 'submit') then
              if (req_params.key? "#{prefix}#{name}") then
                controller.__send__(form_entry[:writer], true)
              else
                controller.__send__(form_entry[:writer], false)
              end
            end
          when :radio_group, :select
            if (value = req_params["#{prefix}#{name}"]) then
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

              if (form_entry[:type] == :select && form_entry[:options][:multiple]) then
                controller.__send__(form_entry[:writer], values)
              else
                controller.__send__(form_entry[:writer], value)
              end
            end
          else
            raise "unknown form export type at `#{name}': #{form_entry[:type]}"
          end
        end

        nil
      end

      def find_first_action(controller, req_params, prefix='')
        action_export = find_action_export(controller.class)
        for name, action_entry in action_export
          case (action_entry[:type])
          when :action, :submit
            if (req_params.key? "#{prefix}#{name}") then
              return controller.method(name)
            end
          when :foreach
            if (list = controller.__send__(name)) then
              list.each_with_index do |c, i|
                if (action = find_first_action(c, req_params, "#{prefix}#{name}(#{i}).")) then
                  return action
                end
              end
            end
          when :import
            if (c = controller.__send__(name)) then
              if (action = find_first_action(c, req_params, "#{prefix}#{name}.")) then
                return action
              end
            end
          else
            raise "unknown action export type at `#{name}': #{action_entry[:type]}"
          end
        end

        nil
      end
    end

    attr_writer :r

    def page_around
      yield
    end

    def page_start
    end

    def page_validation_preprocess
      @r.validation = true
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
      options = { :escape => true }.merge(options)
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

    def gluon_cond_not(name, options={})
      unless (public_method_defined? name) then
        raise NoMethodError, "not defineid method `#{name}' of `#{self}'"
      end
      class_eval(<<-EOF, "#{__FILE__}:gluon_cond_not(#{name})", __LINE__ + 1)
        def not_#{name}
          ! #{name}
        end
      EOF
      gluon_cond("not_#{name}", options)
    end
    private :gluon_cond_not

    def gluon_foreach(name, options={})
      Controller.gluon_form_export(self, name, :foreach, options)
      Controller.gluon_action_export(self, name, :foreach, options)
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
      Controller.gluon_view_export(self, name, :action, options)
      Controller.gluon_action_export(self, name, :action, options)
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
      options = options.merge(:block => block)
      Controller.gluon_form_export(self, name, :import, options)
      Controller.gluon_action_export(self, name, :import, options)
    end
    private :gluon_import

    def gluon_import_reader(name, options={}, &block)
      class_eval{ attr_reader(name) } # why is class_eval necessary?
      gluon_import(name, options, &block)
    end
    private :gluon_import_reader

    def gluon_submit(name, options={})
      Controller.gluon_view_export(self, name, :submit, options)
      Controller.gluon_action_export(self, name, :submit, options)
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

    def gluon_radio_group(name, list, options={})
      options = options.merge(:list => list)
      Controller.gluon_form_export(self, name, :radio_group, options)
      Controller.gluon_form_params(self, name, :writer => "#{name}=".to_sym)
    end
    private :gluon_radio_group

    def gluon_radio_group_accessor(name, list, options={})
      class_eval{ attr_accessor(name) } # why is class_eval necessary?
      gluon_radio_group(name, list, options)
    end
    private :gluon_radio_group_accessor

    def gluon_radio_button(name, group, options={})
      options = options.merge(:group => group.to_sym)
      Controller.gluon_view_export(self, name, :radio_button, options)
    end
    private :gluon_radio_button

    def gluon_radio_button_reader(name, group, options={})
      class_eval{ attr_reader(name) } # why is class_eval necessary?
      gluon_radio_button(name, group, options)
    end
    private :gluon_radio_button_reader

    def gluon_select(name, list, options={})
      options = options.merge(:list => list)
      options = { :multiple => false }.merge(options)
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

    def page_encoding
      raise "not defined page encoding for component of `#{self}'"
    end

    def page_template
      nil
    end

    def process_view(po)
      po.template_render(page_view, page_encoding, page_template)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
