#!/usr/local/bin/ruby

require 'gluon'
require 'store_test_helper'
require 'test/unit'

module Gluon::Test
  class FileStoreTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    include SessionStoreTestHelper

    def setup
      @store_path = 'session'
      FileUtils.rm_rf(@store_path) if $DEBUG
      @store = Gluon::FileStore.new(@store_path, :expire_interval => 0)
    end

    def teardown
      @store.close
      FileUtils.rm_rf(@store_path) unless $DEBUG
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
