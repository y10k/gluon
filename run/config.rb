# gluon configuration

port 9202
access_log '@?/access.log'

require 'Welcom'
require 'Example'

mount Welcom,                '/'
mount Example,               '/example'
mount Example::Menu,         '/example/menu'
mount Example::ExamplePanel, '/example/ex_panel'
mount Example::CodePanel,    '/example/code_panel'
mount Example::ViewPanel,    '/example/view_panel'

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
