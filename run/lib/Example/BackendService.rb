# -*- coding: utf-8 -*-

class Example
  class BackendService < Gluon::Controller
    include Gluon::Validation
    include Gluon::Web::ErrorMessages::AddOn
    include Gluon::Web::OneTimeToken::AddOn

    def_page_encoding __ENCODING__

    # for Example::Menu and Example::Panel
    def self.description
      'backend service'
    end

    def title
      self.class.description
    end
    gluon_value :title

    def create_error_messages
      Gluon::Web::ErrorMessages.new(:head_level => 3)
    end

    def page_around
      read_only = ! @r.equest.post?
      @bbs_db = @r.svc.bbs_db
      @bbs_db.transaction(read_only) {
        yield
      }
    end

    def page_start
      @header_footer = HeaderFooter.new(@r, self.class)
      @comment = nil
      @name = nil
      @clear_on_post = true
    end

    def request_POST
      validation(@errors) do |v|
        v.one_time_token
        v.encoding_everything
        v.not_blank :comment
        v.not_blank :name
      end
    end

    gluon_import_reader :header_footer
    gluon_textarea_accessor :comment,
      :attrs => { 'id' => 'comment', 'cols' => 80, 'rows' => 8 }
    gluon_text_accessor :name, :attrs => { 'id' => 'name' }
    gluon_checkbox_accessor :clear_on_post, :attrs => { 'id' => 'clear-on-post' }

    def post_comment
      @bbs_db[:comments] ||= []
      @bbs_db[:comments] << {
        :comment => @comment,
        :name => @name,
        :timestamp => Time.now
      }
      @comment = nil if @clear_on_post
    end
    gluon_submit :post_comment

    class PostedComment
      extend Gluon::Component

      def initialize(params)
        @posted_comment = params[:comment]
        @posted_name = params[:name]
        @timestamp = params[:timestamp]
      end

      gluon_value_reader :posted_comment
      gluon_value_reader :posted_name

      def timestamp
        @timestamp.strftime("%Y-%m-%d %H:%M:%S")
      end
      gluon_value :timestamp
    end

    def posted_comments
      (@bbs_db[:comments] || []).reverse.map{|params| PostedComment.new(params) }
    end
    gluon_foreach :posted_comments
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
