require 'helper'
require 'omniauth-traity'


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
