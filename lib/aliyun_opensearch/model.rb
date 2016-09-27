require 'aliyun_opensearch/results'
require 'active_support/concern'

module OpenSearch
  module Model
    extend ActiveSupport::Concern

    included do
      has_opensearch_table self.table_name
      has_opensearch_key :id
    end

    module ClassMethods
      def has_opensearch_key key
        cattr_accessor :opensearch_key
        self.opensearch_key = key
      end

      def has_opensearch_app app
        cattr_accessor :opensearch_app
        self.opensearch_app = app
      end

      def has_opensearch_table table
        cattr_accessor :opensearch_table
        self.opensearch_table = table
      end

      def search q
        return OpenSearch::Results.new(self, {
          app: opensearch_app,
          query: {query: "default:'#{q}'"},
          args: {start: 0, hit: 10, fetch_fields: opensearch_key},
        })
      end

      def suggest
      end
    end
  end
end
