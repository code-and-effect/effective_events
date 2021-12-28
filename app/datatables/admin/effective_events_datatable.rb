module Admin
  class EffectiveEventsDatatable < Effective::Datatable
    datatable do
      col :updated_at, visible: false
      col :created_at, visible: false

      col :id, visible: false

      col :title

      actions_col
    end

    collection do
      Effective::Event.deep.all
    end

  end
end
