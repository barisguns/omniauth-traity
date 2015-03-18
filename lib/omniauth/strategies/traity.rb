require 'omniauth/strategies/oauth2'
require 'base64'

module OmniAuth
  module Strategies
    class Traity < OmniAuth::Strategies::OAuth2
      class NoAuthorizationCodeError < StandardError; end

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

      def callback_phase
        with_authorization_code! do
          super
        end
      rescue NoAuthorizationCodeError => e
        fail!(:no_authorization_code, e)
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

      private
      def signed_request_from_cookie
        @signed_request_from_cookie ||= raw_signed_request_from_cookie && parse_signed_request(raw_signed_request_from_cookie)
      end

       def raw_signed_request_from_cookie
        request.cookies["tsr_#{client.id}"]
      end

      def with_authorization_code!
        if request.params.key?('code')
          yield
        elsif code_from_signed_request = signed_request_from_cookie && signed_request_from_cookie['code']
          request.params['code'] = code_from_signed_request
          @authorization_code_from_signed_request_in_cookie = true
          original_provider_ignores_state = options.provider_ignores_state
          options.provider_ignores_state = true
          begin
            yield
          ensure
            request.params.delete('code')
            @authorization_code_from_signed_request_in_cookie = false
            options.provider_ignores_state = original_provider_ignores_state
          end
        else
          raise NoAuthorizationCodeError, 'must pass either a `code` (via URL or by an `fbsr_XXX` signed request cookie)'
        end
      end

      def parse_signed_request(value)
        signature, encoded_payload = value.split('.')
        return if signature.nil?

        decoded_hex_signature = base64_decode_url(signature)
        decoded_payload = MultiJson.decode(base64_decode_url(encoded_payload))

        if valid_signature?(client.secret, decoded_hex_signature, encoded_payload)
          decoded_payload
        end
      end

      def valid_signature?(secret, signature, payload)
        Digest::SHA256.hexdigest("#{payload}-#{secret}") == signature
      end

      def base64_decode_url(value)
        value += '=' * (4 - value.size.modulo(4))
        Base64.decode64(value.tr('-_', '+/'))
      end
    end
  end
end
