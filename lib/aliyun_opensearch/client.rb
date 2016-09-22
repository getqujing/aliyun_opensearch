require 'time'
require 'erb'
require 'openssl'
require 'base64'
require 'json'
require 'rest-client'

module OpenSearch
  class Client
    DEFAULT_ARGS = {
      "Version" => "2",
      "SignatureMethod" => "HMAC-SHA1",
      "SignatureVersion" => "1.0"
    }
    DEFAULT_DIGEST = OpenSSL::Digest.new('sha1')

    # settings = {
    #   endpoint: "",
    #   access_key_id: "",
    #   access_key_secret: "",
    # }
    @@settings = {}
    def self.settings
      @@settings
    end

    def self.settings=(settings)
      @@settings = settings
    end

    def settings
      Client.settings
    end

    def index index, table, items
      upload :add, index, table, items
    end

    def update index, table, items
      upload :update, index, table, items
    end

    def delete index, table, items
      upload :delete, index, table, items
    end

    def upload cmd, index, table, items
      check_settings!
      q = new_query.merge({
        "action" => "push",
        "table_name" => table,
        "items" => JSON.generate([items].flatten.collect {|i| {cmd: cmd, fields: i}}),
        "sign_mode" => "1"
      })
      signature = sign(:post, q)
      payload = q.delete("items") # no items in final url
      perform(:post, "/index/doc/#{index}?#{query_string(q)}&Signature=#{signature}", items: payload)
    end

    # user has responsibility to build subqueries include:
    # query, filter, sort, aggregate, distinct, kvpair
    #
    # args contains all other search arguments
    def search index, query={}, args={}
      check_settings!
      start = args[:start] || 0
      hit = args[:hit] || 10
      qs = "config=format:json,start:#{start},hit:#{hit}&&query=#{query[:query]}"
      %i(filter sort aggregate distinct kvpair).each do |sq|
        qs += "&&#{sq}=#{query[sq]}" if query.include? sq
      end

      q = new_query.merge({
        "index_name" => index,
        "query" => qs,
      })
      args.each {|k, v| q[k.to_s] = v.to_s unless %i(start hit).include? k}
      signature = sign(:get, q)
      perform(:get, "/search?#{query_string(q)}&Signature=#{signature}")
    end

    def suggest args={}
      raise OpenSearchException, "not implement yet"
    end

    private
    def new_query
      DEFAULT_ARGS.merge({
        "SignatureNonce" => SecureRandom.hex,
        "Timestamp" => Time.now.utc.iso8601.to_s,
        "AccessKeyId" => settings[:access_key_id]
      })
    end

    def perform method, uri, body={}
      response = begin
                   unless body.empty?
                     RestClient.__send__ method, "#{settings[:endpoint]}#{uri}", body,
                       user_agent: "OpenSearch Gem #{OpenSearch::VERSION}"
                   else
                     RestClient.__send__ method, "#{settings[:endpoint]}#{uri}",
                       user_agent: "OpenSearch Gem #{OpenSearch::VERSION}"
                   end
                 rescue RestClient::Exception => e
                   e.response
                 end
      r = JSON.parse(response.body)
      if r["status"] == "OK"
        r["result"]
      else
        message = r["errors"].collect {|e| "#{e["code"]}: #{e["message"]}"}.join(", ")
        raise OpenSearchException, message
      end
    end

    def sign method, query
      digest = OpenSSL::HMAC.digest(DEFAULT_DIGEST, "#{settings[:access_key_secret]}&",
                                    "#{method.to_s.upcase}&%2F&#{ERB::Util.url_encode(query_string(query))}")
      ERB::Util.url_encode(Base64.strict_encode64(digest))
    end

    def query_string query
      if query["sign_mode"] == "1"
        query.keys.sort.reject {|k| k == "items"}.collect {|k| "#{k.to_s}=#{ERB::Util.url_encode(query[k].to_s)}"}.join("&")
      else
        query.keys.sort.collect {|k| "#{k.to_s}=#{ERB::Util.url_encode(query[k].to_s)}"}.join("&")
      end
    end

    def check_settings!
      raise OpenSearchException, "no settings provided." if settings.nil?
      %i(endpoint access_key_id access_key_secret).each do |k|
        raise OpenSearchException, "no #{k.to_s} settings provided." if settings[k].nil?
      end
    end
  end
end
