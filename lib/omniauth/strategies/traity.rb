require 'omniauth/strategies/oauth2'
require 'base64'
require 'openssl'

module OmniAuth
  module Strategies
    class Traity < OmniAuth::Strategies::OAuth2
      DEFAULT_SCOPE = 'email'

      option :fields, [:name, :email]
      option :uid_field, :id

      option :client_options, {
        site:          'https://api.traity.com/',
        authorize_url: 'https://traity.com/oauth/dialog',
        token_url:     'oauth/token'
      }

      option :token_params, {
        :parse => :query
      }

      option :authorize_options, [:scope, :display]

      uid { raw_info['id'] }

      info do
        prune!({
          'name' => raw_info['name'],
          'email' => raw_info['email'],
          'bio' => raw_info['bio'],
          'picture' => raw_info['picture'],
          'cover_picture' => raw_info['cover_picture'],
          'gender' => raw_info['gender'],
          'location' => raw_info['location'],
          'reputation' => (raw_info['reputation'] || 0),
          'email_verified' => (raw_info['verified'] || {}).has_key?('email')
        })
      end

      def callback_url
        options[:callback_url] || super
      end

      def authorize_params
        super.tap do |params|
          %w[display scope].each do |v|
            if request.params[v]
              params[v.to_sym] = request.params[v]
            end
          end

          params[:scope] ||= DEFAULT_SCOPE
        end
      end

      def raw_info
        @raw_info ||= access_token.get('1.0/me', info_options).parsed || {}
      end

      def info_options
        params = {:appsecret_proof => appsecret_proof}
        params.merge!({:locale => options[:locale]}) if options[:locale]
        { :params => params }
      end

      def prune!(hash)
        hash.delete_if do |_, value|
          prune!(value) if value.is_a?(Hash)
          value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end
      end

      def appsecret_proof
        @appsecret_proof ||= OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, client.secret, access_token.token)
      end
    end
  end
end
