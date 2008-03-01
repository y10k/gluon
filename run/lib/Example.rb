# example top page

class Example
  autoload :Action, 'Example/Action'
  autoload :Checkbox, 'Example/Checkbox'
  autoload :CodePanel, 'Example/CodePanel'
  autoload :Cond, 'Example/Cond'
  autoload :Dispatch, 'Example/Dispatch'
  autoload :ExamplePanel, 'Example/ExamplePanel'
  autoload :Foreach, 'Example/Foreach'
  autoload :Header, 'Example/Header'
  autoload :Import, 'Example/Import'
  autoload :Link, 'Example/Link'
  autoload :Menu, 'Example/Menu'
  autoload :Password, 'Example/Password'
  autoload :Radio, 'Example/Radio'
  autoload :Select, 'Example/Select'
  autoload :Session, 'Example/Session'
  autoload :Submit, 'Example/Submit'
  autoload :Subpage, 'Example/Subpage'
  autoload :Text, 'Example/Text'
  autoload :Textarea, 'Example/Textarea'
  autoload :Value, 'Example/Value'
  autoload :ViewPanel, 'Example/ViewPanel'

  def menu
    Example::Menu
  end

  def panel
    return Example::ExamplePanel, :path_info => '/value'
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
