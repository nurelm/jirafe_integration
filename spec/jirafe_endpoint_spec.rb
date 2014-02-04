require 'spec_helper'

describe JirafeEndpoint do
  def app
    JirafeEndpoint
  end

  def auth
    {'HTTP_X_AUGURY_TOKEN' => '6a204bd89f3c8348afd5c77c717a097a', "CONTENT_TYPE" => "application/json"}
  end

  let(:order) { Factories.order }
  let(:original) { Factories.original }
  let(:params) { Factories.parameters }

  describe '/import_order' do
    context 'success' do
      it 'imports new orders' do
        message = {
          message_id: '123456',
          message: 'order:new',
          payload: {
            order: order,
            original: original,
            parameters: params
          }
        }.to_json

        VCR.use_cassette('import_new_order') do
          post '/import_order', message, auth
          last_response.status.should == 200
          last_response.body.should match /cart event/
          last_response.body.should match /order-placed event/
          last_response.body.should match /order-accepted event/
        end
      end

      it 'imports updated orders' do
        message = {
          message_id: '123456',
          message: 'order:updated',
          payload: {
            order: order,
            original: original,
            parameters: params,
            diff: original
          }
        }.to_json

        VCR.use_cassette('import_updated_order') do
          post '/import_order', message, auth
          last_response.status.should == 200
          last_response.body.should match /order-accepted event/
        end
      end
    end

    context 'failure' do
      it 'returns error details 'do
        order = Factories.order.merge({ :number => nil })

        message = {
          message_id: '123456',
          message: 'order:new',
          payload: {
            order: order,
            original: original,
            parameters: params
          }
        }.to_json

        VCR.use_cassette('import_order_fail') do
          post '/import_order', message, auth
          last_response.status.should == 500
          last_response.body.should match /None is not of type/
        end
      end
    end
  end

  describe '/import_cart' do
    context 'success' do
      it 'imports carts' do
        message = {
          message_id: '123456',
          message: 'cart:new',
          payload: {
            cart: order,
            original: original,
            parameters: params
          }
        }.to_json

        VCR.use_cassette('import_new_cart') do
          post '/import_cart', message, auth
          last_response.status.should == 200
          last_response.body.should match /cart event/
        end
      end
    end

    context 'failure' do
      order = Factories.order
      order['totals']['order'] = nil

      it 'returns error details' do
        message = {
          message_id: '123456',
          message: 'cart:new',
          payload: {
            cart: order,
            original: original,
            parameters: params
          }
        }.to_json

        VCR.use_cassette('import_new_cart_fail') do
          post '/import_cart', message, auth
          last_response.status.should == 500
          last_response.body.should match /None is not of type/
        end
      end
    end
  end

  describe '/import_product' do
    context 'success' do
      it 'imports a product' do
        message = {
          message_id: '123456',
          message: 'product:persist',
          payload: Factories.product.merge(parameters: params)
        }.to_json

        VCR.use_cassette('import_new_product') do
          post '/import_product', message, auth
          last_response.status.should == 200
          last_response.body.should match /Product sent/
        end
      end
    end

    context 'failure' do
      product = Factories.order
      product['id'] = nil

      it 'returns error details' do
        message = {
          message_id: '123456',
          message: 'product:persist',
          payload: product.merge(parameters: params)
        }.to_json

        VCR.use_cassette('import_new_product_fail') do
          post '/import_product', message, auth
          last_response.status.should == 500
          last_response.body.should match /None is not of type/
        end
      end
    end
  end
end
