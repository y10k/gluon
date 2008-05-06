# gluon configuration

port 9202
log_file "#{base_dir}/gluon.log"
log_level Logger::DEBUG
access_log "#{base_dir}/access.log"

require 'Welcom'
require 'Example'

# for debug
#page_cache false
#auto_reload true

# for product
#page_cache true
#auto_reload false

mount Welcom, '/'
mount Example, '/example'
mount Example::Menu, '/example/menu'
mount Example::ExamplePanel, '/example/ex_panel'
mount Example::CodePanel, '/example/code_panel'
mount Example::ViewPanel, '/example/view_panel'
mount Example::PageCache, '/example/ex_panel/pagecache' # ignored `Example::Panel'

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
