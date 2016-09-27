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

      def quoted(s)
        [String, Symbol].include?(s.class) ? "\"#{s.to_s}\"" : s.to_s
      end

      def search q, f={}
        f = f.collect {|k, v| "#{k}=#{quoted(v)}"}.join(" AND ")
        puts f
        query = {query: "default:'#{q}'"}
        query[:filter] = f if f.present?
        self.internal_search(query)
      end

      def internal_search query={}, args={}
        client = OpenSearch::Client.new
        # overwrite fetch_fields to only fetch the primary key, we will load data from database

        args.update(fetch_fields: opensearch_key)
        args = {start: 0, hit: 10}.merge(args)
        request = {
          app: opensearch_app,
          query: query,
          args: args,
        }
        return OpenSearch::Results.new(self, request)
      end

      def suggest
      end
    end
  end
end
