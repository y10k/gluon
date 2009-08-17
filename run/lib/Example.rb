# -*- coding: utf-8 -*-

class Example
  include Gluon::Controller

  def self.page_encoding
    __ENCODING__
  end

  def request_GET
  end

  def menu
    Example::Menu
  end
  gluon_frame :menu, :attrs => { 'name' => 'menu' }

  def panel
    item = Menu::Items.values.first
    return ExamplePanel, item.example_type
  end
  gluon_frame :panel, :attrs => { 'name' => 'main' }

  autoload :Action, 'Example/Action'
  autoload :BackendService, 'Example/BackendService'
  autoload :Checkbox, 'Example/Checkbox'
  autoload :CodePanel, 'Example/CodePanel'
  autoload :CompositeForm, 'Example/CompositeForm'
  autoload :Cond, 'Example/Cond'
  autoload :ExamplePanel, 'Example/ExamplePanel'
  autoload :Foreach, 'Example/Foreach'
  autoload :Header, 'Example/Header'
  autoload :Import, 'Example/Import'
  autoload :Link, 'Example/Link'
  autoload :Menu, 'Example/Menu'
  autoload :Passwd, 'Example/Passwd'
  autoload :Radio, 'Example/Radio'
  autoload :Select, 'Example/Select'
  autoload :Submit, 'Example/Submit'
  autoload :Text, 'Example/Text'
  autoload :Textarea, 'Example/Textarea'
  autoload :Value, 'Example/Value'
  autoload :ViewPanel, 'Example/ViewPanel'
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
