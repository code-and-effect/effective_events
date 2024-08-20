module Effective
  class EventRegistrantsSelect2AjaxController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)

    include Effective::Select2AjaxController

    def users
      authorize! :users, Effective::EventRegistrant

      collection = current_user.class.all

      respond_with_select2_ajax(collection, skip_authorize: true) do |user|
        data = { first_name: user.first_name, last_name: user.last_name, email: user.email }

        if user.class.try(:effective_memberships_organization_user?)
          data[:company] = user.organizations.map(&:to_s).join(', ')
        end

        { 
          id: user.to_param, 
          text: to_select2(user),
          data: data
        }
      end
    end

    private

    def to_select2(resource)
      organizations = Array(resource.try(:organizations)).join(', ')

      [
        "<span>#{resource}</span>",
        "<small>&lt;#{resource.email}&gt;</small>",
        ("<small>#{organizations}</small>" if organizations.present?)
      ].compact.join(' ')
    end

  end
end
