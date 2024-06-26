class Admin::EffectiveEventRegistrationsDatatable < Effective::Datatable
  datatable do
    order :created_at

    col :token, visible: false

    col :created_at, label: 'Created', visible: false
    col :updated_at, label: 'Updated', visible: false

    col :submitted_at, label: 'Submitted', as: :date
    col :completed_at, label: 'Completed', as: :date

    col :event, search: :string
    col :owner

    col :event_registrants, search: :string, visible: false
    col :event_addons, search: :string, visible: false
    col :orders, label: 'Order'

    actions_col
  end

  collection do
    EffectiveEvents.EventRegistration.all.deep.where.not(status: :draft)
  end

end
