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

  autoload :CodePanel, 'Example/CodePanel'
  autoload :ExamplePanel, 'Example/ExamplePanel'
  autoload :Menu, 'Example/Menu'
  autoload :Value, 'Example/Value'
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
