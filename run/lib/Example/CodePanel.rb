# -*- coding: utf-8 -*-

require 'Example/Panel'

class Example
  class CodePanel < Panel
    def self.page_encoding
      __ENCODING__
    end

    LIB_DIR = File.join(File.dirname(__FILE__), '..')

    def request_GET(key)
      super
      @source_path = File.join(LIB_DIR,
                               @example_type.name.gsub(/::/, '/') + '.rb')
    end

    def filename
      File.basename(@source_path)
    end
    gluon_value :filename

    def source_code
      File.open(@source_path, "r:#{@example_type.page_encoding}") {|f| f.read }
    end
    gluon_value :source_code
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
