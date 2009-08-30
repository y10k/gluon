# gluon configuration

use Rack::ShowExceptions        # for debug
use Rack::Reloader              # for debug
use Rack::Session::Cookie, :secret => IO.read("#{base_dir}/seed")

## :example:start

require 'Example'
require 'Welcom'

map '/' do |entry|
  entry.mount Welcom
end

map '/example'do |entry|
  entry.mount Example
end

map '/example/menu' do |entry|
  entry.mount Example::Menu
end

map '/example/ex_panel' do |entry|
  entry.mount Example::ExamplePanel
end

map '/example/code_panel' do |entry|
  entry.mount Example::CodePanel
end

map '/example/view_panel' do |entry|
  entry.mount Example::ViewPanel
end

map '/example/ex_panel/OneTimeToken' do |entry|
  entry.mount Example::OneTimeToken
end

map '/example/ex_panel/BackendService' do |entry|
  entry.mount Example::BackendService
end

backend_service :bbs_db do |service|
  require 'pstore'
  service.start do
    PStore.new("#{base_dir}/bbs_data.pstore")
  end
  service.stop do |bbs_db|
    # nothing to do.
  end
end

## :example:stop

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
