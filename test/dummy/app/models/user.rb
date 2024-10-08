class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  acts_as_addressable :billing

  effective_devise_user                    # effective_resources
  effective_memberships_user
  effective_memberships_organization_user

  # For the test/models/event_registrants_test.rb:38 test
  def membership_present?
    membership.present? || roles.include?(:member)
  end
end
