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
  autoload :CodePanel, 'Example/CodePanel'
  autoload :Cond, 'Example/Cond'
  autoload :ExamplePanel, 'Example/ExamplePanel'
  autoload :Foreach, 'Example/Foreach'
  autoload :Header, 'Example/Header'
  autoload :Import, 'Example/Import'
  autoload :Link, 'Example/Link'
  autoload :Menu, 'Example/Menu'
  autoload :Submit, 'Example/Submit'
  autoload :Value, 'Example/Value'
  autoload :ViewPanel, 'Example/ViewPanel'
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
