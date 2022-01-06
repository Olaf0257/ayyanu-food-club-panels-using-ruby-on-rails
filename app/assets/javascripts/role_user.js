$(document).ready(function () {
  if($("#inactive_count").val() == 0) {
    $(".inactive-counter").hide();
  }

  $('#approve-multiple').on("click", function () {
    if ($('input[name^=users]:checked').length <= 0) {
      swal("Select users!", "Please select at least one checkbox", "warning")
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

  $('.delete_user').click(function() {
    var user=$(this).attr("value")
    swal({
      title: "Are you sure?",
      text: "Do you want to delete this user !",
      type: "warning",
      showCancelButton: true,
      confirmButtonColor: "#DD6B55",
      confirmButtonText: "Yes, Delete it!",
      cancelButtonText: "No, cancel plz!",
      closeOnConfirm: false,
      closeOnCancel: false
    },
    function(isConfirm){
      if (isConfirm) {
        $.ajax({
          type: "GET",
          url: "/user/delete_role_user",
          data: {user_id: user},
          dataType: "JSON",
          success:function(data){
            if(data.code==200){
              swal("Deleted!","User has been deleted","success")
                document.getElementById("user-"+user+"").outerHTML="";
            }
          },
          error: function() {
            swal("error",data.response_message,"error")
          }
        });
      }
      else
      {
        swal("Cancelled", "No change in User", "error");
      }
    });
  });

  $("#update_role").on("click",function(){
    var country_code = $("#user_contact").intlTelInput("getSelectedCountryData");
    $("#country-code").val(country_code.dialCode)
  });

  $("#country-code").val($("#country-code").val())
    $("#create_role").on("click",function(){
    var country_code = $("#contact").intlTelInput("getSelectedCountryData");
    $("#country-code").val(country_code.dialCode)
  });

  $("#role_user_password_update").on("click",function(){
    var passlength = new RegExp("(?=.{6,})");

    if($("#new_password").val().trim() == "") {
      $("#new_password").focus();
      swal("Warning", "New password can't be blank", "error");
      return false;
    } else if(!(passlength.test($("#new_password").val()))) {
      $("#new_password").focus();
      swal("Warning", "Password length should be 6 character long", "error");
      return false;
    } else if($("#new_password").val() != $("#confirm_password").val()) {
      $("#confirm_password").focus();
      swal("Warning", "Password  and confirm password do not match", "error");
      return false;
    } else if($("#new_password").val().length <= 5 || $('#new_password').val().length >= 13 ) {
      $("#new_password").focus();
      swal("Warning", "Please enter new password between length 6 to 12", "error");
      return false;
    } else {
      return true;
    }
  });
});
