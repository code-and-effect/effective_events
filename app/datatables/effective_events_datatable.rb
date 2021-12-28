# Dashboard Events
class EffectiveEventsDatatable < Effective::Datatable
  datatable do
    order :title
    col :id, visible: false

    col :title

    actions_col
  end

  collection do
    Effective::Event.deep.all
  end

end
