require 'test_helper'

class EventsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  tests Effective::EventsController

  setup do
    @routes = EffectiveEvents::Engine.routes
    @controller.define_singleton_method(:impersonating?) { false }
    @controller.class.helper_method(:impersonating?)
  end

  test 'raises record not found before rendering for an invalid page' do
    error = assert_raises(ActiveRecord::RecordNotFound) do
      get :index, params: { page: 'invalid' }
    end

    assert_equal 'Page "invalid" is invalid', error.message
  end

  test 'raises record not found before rendering for a page beyond the results' do
    error = assert_raises(ActiveRecord::RecordNotFound) do
      get :index, params: { page: 2 }
    end

    assert_equal 'Page 2 does not exist', error.message
  end

  test 'renders a valid page and reuses its collection count' do
    create_event

    counts = []
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, _start, _finish, _id, payload|
      counts << payload[:sql] if payload[:sql].match?(/SELECT COUNT\(\*\).*"events"/)
    end

    get :index, params: { page: 1 }

    assert_response :success
    assert_equal 1, counts.length
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  test 'events index shows hidden and draft events only to admins' do
    hidden = create_event.tap { |event| event.update!(hidden: true) }
    draft = create_event.tap(&:draft!)

    get :index

    assert @controller.view_assigns['events'].include?(hidden)
    assert @controller.view_assigns['events'].include?(draft)
    assert_select '.badge', text: 'HIDDEN'

    @controller.define_singleton_method(:authorize!) do |action, _resource|
      action != :admin
    end

    get :index

    refute @controller.view_assigns['events'].include?(hidden)
    refute @controller.view_assigns['events'].include?(draft)
  end

  test 'hidden events remain directly accessible and registerable' do
    hidden = create_event.tap { |event| event.update!(hidden: true) }

    get :show, params: { id: hidden.to_param }

    assert_includes response.body, 'This event is hidden from the events page and sitemap.'

    @controller.define_singleton_method(:authorize!) do |action, _resource|
      action != :admin
    end

    get :show, params: { id: hidden.to_param }

    assert_response :success
    assert_select 'a', text: 'Register'
  end
end
