# example top page

class Example
  include Gluon::Controller
  include Gluon::ERBView

  def page_get
  end

  def menu
    Example::Menu
  end

  def panel
    key = DispatchController::EXAMPLE_KEYS[0]
    example = DispatchController::EXAMPLES[key][:class]
    return ExamplePanel, :path_args => [ example ]
  end

  autoload :Action, 'Example/Action'
  autoload :Checkbox, 'Example/Checkbox'
  autoload :CodePanel, 'Example/CodePanel'
  autoload :Cond, 'Example/Cond'
  autoload :DispatchController, 'Example/DispatchController'
  autoload :ErrorMessages, 'Example/ErrorMessages'
  autoload :ExamplePanel, 'Example/ExamplePanel'
  autoload :Foreach, 'Example/Foreach'
  autoload :Header, 'Example/Header'
  autoload :Import, 'Example/Import'
  autoload :Link, 'Example/Link'
  autoload :Menu, 'Example/Menu'
  autoload :OneTimeToken, 'Example/OneTimeToken'
  autoload :PageCache, 'Example/PageCache'
  autoload :Password, 'Example/Password'
  autoload :Radio, 'Example/Radio'
  autoload :Select, 'Example/Select'
  autoload :Session, 'Example/Session'
  autoload :Submit, 'Example/Submit'
  autoload :Table, 'Example/Table'
  autoload :Text, 'Example/Text'
  autoload :Textarea, 'Example/Textarea'
  autoload :Value, 'Example/Value'
  autoload :ViewPanel, 'Example/ViewPanel'
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
