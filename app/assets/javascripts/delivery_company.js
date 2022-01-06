$(document).on("click", ".reject-company-btn", function() {
  $("#reject_company_modal").modal("show");
  $("#company_id").val($(this).data("id"));
});

$(document).on("click", ".company-reject-submit", function() {
  var id = $("#company_id").val();;
  var reason = $("#company_reject_reason").val();

  if($.trim(reason) == "") {
    swal("Warning", "Please Enter the Rejection Reason", "warning");
  } else {
    $.get("/delivery_companies/" + id + "/reject?reject_reason=" + reason);
    $("#reject_company_modal").modal("hide");
    $("#company-" + id).remove();
    swal("Success", "Company Rejected Successfully!", "success");
    window.location.reload();
  }
});

$(document).on("change", ".delivery-company-country-select", function() {
  var country = $(".delivery-company-country-select option:selected").text();
  $.get("/delivery_companies/state_list?country=" + country);
});

$(document).on("change", ".delivery-company-state-select", function() {
  var states = $(".delivery-company-state-select").val();

  if ($(".delivery-company-country-select").length > 0) {
    var countryId = $(".delivery-company-country-select").val();
  } else {
    var countryId = $("#delivery_company_country_id").val();
  }

  $.get("/delivery_companies/district_list?states=" + states + "&country_id=" + countryId);
});

$(document).on("change", ".delivery-company-district-select", function() {
  var districtIds = $(".delivery-company-district-select").val();
  $.get("/delivery_companies/zone_list?district_ids=" + districtIds);
});

$(document).on("click", ".reject-amount-settle-btn", function() {
  var id;
  if ($(this)[0].hasAttribute("id")) {
    id = $(this).attr("id").split('-')[0];
  }

  $('#order_id').val(id);
  $("#reject_amount_settle_modal").modal("show");
});

$(document).on("click", ".amount-settle-reject-submit", function() {
  var reason = $("#reason").val();
  var order_id = $("#order_id").val();

  if($.trim(reason) == "") {
    swal("Warning", "Please Enter the Rejection Reason", "warning");
  } else {
    $("#order_id").val(order_id);
    $("#reject_reason").val(reason);
    $(".admin-amount-settle-form").submit();
  }
});

$(document).ready(function () {
  $("#delivery_company_password_update").on("click",function(){
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
