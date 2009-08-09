# -*- coding: utf-8 -*-

class Example
  class CodePanel
    include Gluon::Controller

    def self.page_encoding
      __ENCODING__
    end

    gluon_path_filter %r"^/([A-Za-z]+)$" do |example|
      '/' + Menu::Item.key(example)
    end

    LIB_DIR = File.join(File.dirname(__FILE__), '..')

    def request_GET(key)
      @example_type = Menu::Items[key].example_type
      @source_path = File.join(LIB_DIR,
                               @example_type.name.gsub(/::/, '/') + '.rb')
    end

    def title
      @example_type.description
    end
    gluon_value :title

    def filename
      File.basename(@source_path)
    end
    gluon_value :filename

    def source_code
      File.open(@source_path, "r:#{__ENCODING__}") {|f| f.read }
    end
    gluon_value :source_code
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
