require 'helper'
require 'omniauth-traity'
require 'base64'


class StrategyTest < StrategyTestCase
  include OAuth2StrategyTests
end

class ClientTest < StrategyTestCase
  test 'has correct Traity site' do
    assert_equal 'https://api.traity.com/', strategy.client.site
  end

  test 'has correct authorize url' do
    assert_equal 'https://traity.com/oauth/dialog', strategy.client.options[:authorize_url]
  end

  test 'has correct token url with versioning' do
    @options = {:client_options => {:site => 'https://api.traity.com/1.0'}}
    assert_equal 'oauth/token', strategy.client.options[:token_url]
    assert_equal 'https://api.traity.com/1.0/oauth/token', strategy.client.token_url
  end
end

class CallbackUrlTest < StrategyTestCase
  test "returns the default callback url" do
    url_base = 'http://auth.request.com'
    @request.stubs(:url).returns("#{url_base}/some/page")
    strategy.stubs(:script_name).returns('') # as not to depend on Rack env
    assert_equal "#{url_base}/auth/traity/callback", strategy.callback_url
  end

  test "returns path from callback_path option" do
    @options = { :callback_path => "/auth/traity/done"}
    url_base = 'http://auth.request.com'
    @request.stubs(:url).returns("#{url_base}/page/path")
    strategy.stubs(:script_name).returns('') # as not to depend on Rack env
    assert_equal "#{url_base}/auth/traity/done", strategy.callback_url
  end

  test "returns url from callback_url option" do
    url = 'https://auth.myapp.com/auth/traity/callback'
    @options = { :callback_url => url }
    assert_equal url, strategy.callback_url
  end
end


class AuthorizeParamsTest < StrategyTestCase
  test 'includes default scope for email' do
    assert strategy.authorize_params.is_a?(Hash)
    assert_equal 'email', strategy.authorize_params[:scope]
  end

  test 'includes display parameter from request when present' do
    @request.stubs(:params).returns({ 'display' => 'touch' })
    assert strategy.authorize_params.is_a?(Hash)
    assert_equal 'touch', strategy.authorize_params[:display]
  end

  test 'overrides default scope with parameter passed from request' do
    @request.stubs(:params).returns({ 'scope' => 'email' })
    assert strategy.authorize_params.is_a?(Hash)
    assert_equal 'email', strategy.authorize_params[:scope]
  end
end

class TokenParamsTest < StrategyTestCase
  test 'has correct parse strategy' do
    assert_equal :query, strategy.token_params[:parse]
  end
end

class UidTest < StrategyTestCase
  def setup
    super
    strategy.stubs(:raw_info).returns({ 'id' => '123' })
  end

  test 'returns the id from raw_info' do
    assert_equal '123', strategy.uid
  end
end


class InfoTestOptionalDataPresent < StrategyTestCase
  def setup
    super
    @raw_info ||= { 'name' => 'Sergio Leone' }
    strategy.stubs(:raw_info).returns(@raw_info)
  end

  test 'returns the name' do
    assert_equal 'Sergio Leone', strategy.info['name']
  end

  test 'returns the email' do
    @raw_info['email'] = 'sergio@leone.com'
    assert_equal 'sergio@leone.com', strategy.info['email']
  end

  test 'returns the bio' do
    @raw_info['bio'] = 'Amazing western director'
    assert_equal 'Amazing western director', strategy.info['bio']
  end

  test 'returns the traity avatar url' do
    @raw_info['picture'] = 'http://assets.com/userimage'
    assert_equal 'http://assets.com/userimage', strategy.info['picture']
  end

  test 'returns the traity cover picture' do
    @raw_info['cover_picture'] = 'http://assets.com/coverpicture'
    assert_equal 'http://assets.com/coverpicture', strategy.info['cover_picture']
  end

  test 'returns the gender' do
    @raw_info['gender'] = 'Male'
    assert_equal 'Male', strategy.info['gender']
  end

  test 'returns the location as location' do
    @raw_info['location'] = "Italy"
    assert_equal "Italy", strategy.info['location']
  end

  test 'returns the reputation' do
    @raw_info['reputation'] = 4.3
    assert_equal 4.3, strategy.info['reputation']
  end

  test 'returns true if the email is verified' do
    @raw_info['verified'] = { 'email' => Time.now }
    assert_equal true, strategy.info['email_verified']
  end
end

class InfoTestOptionalDataNotPresent < StrategyTestCase
  def setup
    super
    @raw_info ||= { 'name' => 'Sergio Leone' }
    strategy.stubs(:raw_info).returns(@raw_info)
  end

  test 'has no bio key' do
    refute_has_key 'bio', strategy.info
  end

  test 'has no picture key' do
    refute_has_key 'picture', strategy.info
  end

  test 'has no cover_picture key' do
    refute_has_key 'cover_picture', strategy.info
  end

  test 'has no gender key' do
    refute_has_key 'gender', strategy.info
  end

  test 'has no location key' do
    refute_has_key 'location', strategy.info
  end

  test 'has no reputation' do
    assert_equal 0, strategy.info['reputation']
  end

  test 'has email verified as false' do
    assert_equal false, strategy.info['email_verified']
  end
end

class RawInfoTest < StrategyTestCase
  def setup
    super
    @access_token = stub('OAuth2::AccessToken')
    @appsecret_proof = 'appsecret_proof'
    @options = {:appsecret_proof => @appsecret_proof}
  end

  test 'performs a GET to https://api.traity.com/1.0/me' do
    strategy.stubs(:appsecret_proof).returns(@appsecret_proof)
    strategy.stubs(:access_token).returns(@access_token)
    params = {:params => @options}
    @access_token.expects(:get).with('1.0/me', params).returns(stub_everything('OAuth2::Response'))
    strategy.raw_info
  end

  test 'performs a GET to https://api.traity.com/1.0/me with locale' do
    @options.merge!({ :locale => 'cs_CZ' })
    strategy.stubs(:access_token).returns(@access_token)
    strategy.stubs(:appsecret_proof).returns(@appsecret_proof)
    params = {:params => @options}
    @access_token.expects(:get).with('1.0/me', params).returns(stub_everything('OAuth2::Response'))
    strategy.raw_info
  end

  test 'returns a Hash' do
    strategy.stubs(:access_token).returns(@access_token)
    strategy.stubs(:appsecret_proof).returns(@appsecret_proof)
    raw_response = stub('Faraday::Response')
    raw_response.stubs(:body).returns('{ "ohai": "thar" }')
    raw_response.stubs(:status).returns(200)
    raw_response.stubs(:headers).returns({'Content-Type' => 'application/json' })
    oauth2_response = OAuth2::Response.new(raw_response)
    params = {:params => @options}
    @access_token.stubs(:get).with('1.0/me', params).returns(oauth2_response)
    assert_kind_of Hash, strategy.raw_info
    assert_equal 'thar', strategy.raw_info['ohai']
  end

  test 'returns an empty hash when the response is false' do
    strategy.stubs(:access_token).returns(@access_token)
    strategy.stubs(:appsecret_proof).returns(@appsecret_proof)
    oauth2_response = stub('OAuth2::Response', :parsed => false)
    params = {:params => @options}
    @access_token.stubs(:get).with('1.0/me', params).returns(oauth2_response)
    assert_kind_of Hash, strategy.raw_info
    assert_equal({}, strategy.raw_info)
  end
end


class CredentialsTest < StrategyTestCase
  def setup
    super
    @access_token = stub('OAuth2::AccessToken')
    @access_token.stubs(:token)
    @access_token.stubs(:expires?)
    @access_token.stubs(:expires_at)
    @access_token.stubs(:refresh_token)
    strategy.stubs(:access_token).returns(@access_token)
  end

  test 'returns a Hash' do
    assert_kind_of Hash, strategy.credentials
  end

  test 'returns the token' do
    @access_token.stubs(:token).returns('123')
    assert_equal '123', strategy.credentials['token']
  end

  test 'returns the expiry status' do
    @access_token.stubs(:expires?).returns(true)
    assert strategy.credentials['expires']

    @access_token.stubs(:expires?).returns(false)
    refute strategy.credentials['expires']
  end

  test 'returns the refresh token and expiry time when expiring' do
    ten_mins_from_now = (Time.now + 600).to_i
    @access_token.stubs(:expires?).returns(true)
    @access_token.stubs(:refresh_token).returns('321')
    @access_token.stubs(:expires_at).returns(ten_mins_from_now)
    assert_equal '321', strategy.credentials['refresh_token']
    assert_equal ten_mins_from_now, strategy.credentials['expires_at']
  end

  test 'does not return the refresh token when test is nil and expiring' do
    @access_token.stubs(:expires?).returns(true)
    @access_token.stubs(:refresh_token).returns(nil)
    assert_nil strategy.credentials['refresh_token']
    refute_has_key 'refresh_token', strategy.credentials
  end

  test 'does not return the refresh token when not expiring' do
    @access_token.stubs(:expires?).returns(false)
    @access_token.stubs(:refresh_token).returns('XXX')
    assert_nil strategy.credentials['refresh_token']
    refute_has_key 'refresh_token', strategy.credentials
  end
end

module SignedRequestHelpers
  def signed_request(payload, secret)
    encoded_payload   = base64_encode_url(MultiJson.encode(payload))
    encoded_signature = base64_encode_url(signature(encoded_payload, secret))
    [encoded_signature, encoded_payload].join('.')
  end

  def base64_encode_url(value)
    Base64.encode64(value).tr('+/', '-_').gsub(/\n/, '')
  end

  def signature(payload, secret)
    Digest::SHA256.hexdigest("#{payload}-#{secret}")
  end
end

module SignedRequestTests
  class TestCase < StrategyTestCase
    include SignedRequestHelpers
  end

  class CookieAndParamNotPresentTest < TestCase
    test 'is nil' do
      assert_nil strategy.send(:signed_request_from_cookie)
    end

    test 'throws an error on calling build_access_token' do
      assert_raises(OmniAuth::Strategies::Traity::NoAuthorizationCodeError) { strategy.send(:with_authorization_code!) {} }
    end
  end

  class CookiePresentTest < TestCase
    def setup(algo = nil)
      super()
      @payload = {
        'code' => 'm4c0d3z',
        'issued_at' => Time.now.to_i,
        'user_id' => '123456'
      }

      @request.stubs(:cookies).returns({"tsr_#{@client_id}" => signed_request(@payload, @client_secret)})
    end

    test 'parses the access code out from the cookie' do
      assert_equal @payload, strategy.send(:signed_request_from_cookie)
    end
  end

  class EmptySignedRequestTest < TestCase
    def setup
      super
      @request.stubs(:params).returns({'signed_request' => ''})
    end

    test 'empty param' do
      assert_equal nil, strategy.send(:signed_request_from_cookie)
    end
  end

  class MissingCodeInParamsRequestTest < TestCase
    def setup
      super
      @request.stubs(:params).returns({})
    end

    test 'calls fail! when a code is not included in the params' do
      strategy.expects(:fail!).times(1).with(:no_authorization_code, kind_of(OmniAuth::Strategies::Traity::NoAuthorizationCodeError))
      strategy.callback_phase
    end
  end

  class MissingCodeInCookieRequestTest < TestCase
    def setup(algo = nil)
      super()
      @payload = {
        'code' => nil,
        'issued_at' => Time.now.to_i,
        'user_id' => '123456'
      }

      @request.stubs(:cookies).returns({"tsr_#{@client_id}" => signed_request(@payload, @client_secret)})
    end

    test 'calls fail! when a code is not included in the cookie' do
      strategy.expects(:fail!).times(1).with(:no_authorization_code, kind_of(OmniAuth::Strategies::Traity::NoAuthorizationCodeError))
      strategy.callback_phase
    end
  end
end
