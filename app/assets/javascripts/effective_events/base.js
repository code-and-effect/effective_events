// $(document).on('change', '[data-event-registrant-user-search]', function(event) {
//   let $select = $(event.target);
//   let value = $select.val() || ''

//   console.log("I am here");
//   console.log(event);
// });

$(document).on('select2:select', '[data-event-registrant-user-search]', function(event) {
  var data = event.params.data['data'];
  var $form = $(event.target).closest('.event-registrant-user-fields')

  if(data.first_name) {
    $form.find('[name$="[first_name]"]').val(data.first_name);
  }

  if(data.last_name) {
    $form.find('[name$="[last_name]"]').val(data.last_name);
  }

  if(data.email) {
    $form.find('[name$="[email]"]').val(data.email);
  }

  if(data.company) {
    $form.find('[name$="[company]"]').val(data.company);
  }

});
