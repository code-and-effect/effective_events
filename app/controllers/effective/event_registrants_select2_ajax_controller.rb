module Effective
  class EventRegistrantsSelect2AjaxController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)

    include Effective::Select2AjaxController

    def users
      authorize! :users, Effective::EventRegistrant

      with_organizations = current_user.class.try(:effective_memberships_organization_user?)

      collection = current_user.class.all
      collection = collection.includes(:organizations) if with_organizations

      respond_with_select2_ajax(collection, skip_authorize: true) do |user|
        data = { first_name: user.first_name, last_name: user.last_name, email: user.email }

        if with_organizations
          data[:company] = user.organizations.first.try(:to_s)
          data[:organization_id] = user.organizations.first.try(:id)
        end

        { 
          id: user.to_param, 
          text: to_select2(user),
          data: data
        }
      end
    end

    def organizations
      klass = EffectiveMemberships.Organization
      raise('an EffectiveMemberships.Organization is required') unless klass.try(:effective_memberships_organization?)

      collection = klass.all

      # Authorize
      EffectiveResources.authorize!(self, :member_organizations, collection.klass)

      respond_with_select2_ajax(collection, skip_authorize: true) do |organization|
        { id: organization.to_param, text: organization.to_s }
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
