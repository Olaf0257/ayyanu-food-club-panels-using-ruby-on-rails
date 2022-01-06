$(document).ready(function () {
  $(document).on("click", '.editroles', function (event) {
    $('.chkBoxDiv input:checkbox').each(function () {
      $(this).prop("checked", false);
    });
    var id = $(this).attr("id").split('-')[0]
    var privilegeIds = $("#role-id-" + id).val();
    var privilegeIds = privilegeIds.substring(1);
    var privilegeIdsArr = privilegeIds.split(",");
    $('.chkBoxDiv input:checkbox').each(function () {
      if ($.inArray($(this).val(), privilegeIdsArr) != -1) {
        $(this).prop("checked", true);
      }
    });
    $('#role_id').val(id);
    var name = $("#role-name-" + id).val();
    $('#role_name').val(name);
    $('#role_index').val($("#role_index-" + id).val());
    $('#edit-role-modal').modal({
      backdrop: 'static',
      keyboard: false
    });
    $('#edit-role-modal').modal('show');
  })
  $('#add-role').on("click", function () {
    if ($('#add_role_name').val().trim() == "") {
      $('#add_role_name').focus();
      swal("Role Name can't be blank!", "Please enter role name", "warning")
      return false;
    } else if ($('input[name^=privilege]:checked').length <= 0) {
      swal("Select privileges!", "Please select at least one privilege", "warning")
      return false;
    } else {
      swal({
        html: true,
        title: "Please wait...",
        text: "<img src='/assets/rest-loading.gif' width='20%'>",
        showConfirmButton: false
      });
      return true;
    }
  });
  $("#editrole").on("click", function () {
    if ($('#role_name').val().trim() == "") {
      $('#role_name').focus();
      swal("Role Name can't be blank!", "Please enter role name", "warning")
      return false;
    } else if ($('input[name^=privilege]:checked').length <= 0) {
      swal("Select privileges!", "Please select at least one privilege", "warning")
      return false;
    } else {
      swal({
        html: true,
        title: "Please wait...",
        text: "<img src='/assets/rest-loading.gif' width='20%'>",
        showConfirmButton: false,
        timer: 6000
      });
      return true;
    }
  });
  $("#successMessage").css("display", "none");
  $('.delete_role').click(function () {
    var roleid = $(this).attr("value")
    swal({
        title: "Are you sure?",
        text: "Do you want to delete this role !",
        type: "warning",
        showCancelButton: true,
        confirmButtonColor: "#DD6B55",
        confirmButtonText: "Yes, Delete it!",
        cancelButtonText: "No, cancel plz!",
        closeOnConfirm: false,
        closeOnCancel: false
      },
      function (isConfirm) {
        if (isConfirm) {
          $.ajax({
            type: "POST",
            url: "/remove/role",
            data: {
              role_id: roleid
            },
            dataType: "JSON",
            success: function (data) {
              if (data.code == 200) {
                swal("Deleted!", "Role has been deleted", "success")
                document.getElementById("role-" + roleid + "").outerHTML = "";
              }
            },
            error: function () {
              swal("error", data.response_message, "error")
            }
          });
        } else {
          swal("Cancelled", "No change in Role", "error");
        }
      });
  });
});