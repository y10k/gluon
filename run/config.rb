# gluon configuration

port 9202
access_log '@?/access.log'

require 'Welcom'
require 'Example'

mount Welcom,           '/'
mount Example,          '/example'
mount Example::Menu,    '/example/menu'
mount Example::Value,   '/example/value'
mount Example::Cond,    '/example/cond'
mount Example::Foreach, '/example/foreach'
mount Example::Link,    '/example/link'
mount Example::Import,  '/example/import'

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
