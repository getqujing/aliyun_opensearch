module OpenSearch
  class Results
    include Enumerable

    delegate :first, :last, :each, :empty?, :size, :slice, :[], :to_a, :to_ary, to: :results
    delegate :opensearch_key, to: :klass

    attr_reader :klass, :request

    def initialize(klass, request)
      @klass = klass
      @request = request
      @response = nil
      @results = nil
    end

    def response
      @response ||= execute!
    end

    def results
      @results ||= fetch_results!
    end

    def total
      return response["total"]
    end

    def where options
      return self if options.empty?
      request[:query][:filter] ||= {}
      request[:query][:filter].merge!(options)
      self
    end

    def order options
      return self if options.empty?
      request[:query][:sort] ||= []
      options.each do |k ,v|
        case v
        when :asc, "asc"
          request[:query][:sort] << "+#{k}"
        when :desc, "desc"
          request[:query][:sort] << "-#{k}"
        end
      end
      self
    end

    # Any will_paginate-compatible collection should have these methods:
    #   current_page, page, per_page, total_entries, total_pages
    def paginate(options={})
      page = [options[:page].to_i, 1].max
      per_page = (options[:per_page] || per_page).to_i
      request[:args].update(start: (page - 1) * per_page, hit: per_page)
      self
    end

    def current_page
      request[:args][:start].to_i / per_page + 1
    end

    def page(n)
      paginate(page: n, per_page: per_page)
    end

    def per_page(n=nil)
      if n.nil?
        request[:args][:hit]
      else
        paginate(page: current_page, per_page: n)
      end
    end

    alias_method :total_entries, :total

    def total_pages
      (total / per_page.to_f).ceil
    end

    private

    def execute!
      r = OpenSearch::Client.new.search request[:app], request[:query], request[:args]
      r
    end

    def fetch_results!
      keys = response["items"].collect {|x| x[opensearch_key.to_s]}
      klass.where(opensearch_key => keys).sort {|x, y| keys.index(x.__send__(opensearch_key).to_s) <=> keys.index(y.__send__(opensearch_key).to_s)}
    end

  end
end
