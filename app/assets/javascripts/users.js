$(document).on("click", ".reject-influencer-btn", function(e) {
  $("#reject_influencer_modal").modal("show");
  $("#influencer_id").val($(this).data("id"));
});

$(document).on("click", ".influencer-reject-submit", function(e) {
  var id = $("#influencer_id").val();;
  var reason = $("#influencer_reject_reason").val();

  if($.trim(reason) == "") {
    swal("Warning", "Please Enter the Rejection Reason", "warning");
  } else {
    $.get("/influencer/reject?user_id=" + id + "&reject_reason=" + reason);
    $("#reject_influencer_modal").modal("hide");
    $("#user-" + id).remove();
    swal("Success", "Influencer Rejected Successfully!", "success");
    window.location.reload();
  }
});

$(document).ready(function() {
  $(".update-influencer-btn").on("click",function(){
    var country_code = $("#contact").intlTelInput("getSelectedCountryData");
    $("#country-code").val(country_code.dialCode)
  });

  $("#country-code").val($("#country-code").val());

  $(".create-influencer-btn").on("click",function() {
    var country_code = $("#contact").intlTelInput("getSelectedCountryData");
    $("#country-code").val(country_code.dialCode)
  });
});

$(document).on("click", ".edit-contract", function() {
  var id = $(this).attr("id").split("-")[0];
  $("#edit_contract_id").val(id);
  var startDate = $(this).closest("tr").find(".start-date").data("id");
  var endDate = $(this).closest("tr").find(".end-date").data("id");
  $("#edit_start_date").val(startDate);
  $("#edit_end_date").val(endDate);
  $("#edit_contract_modal").modal({backdrop: "static", keyboard: false});
  $("#edit_contract_modal").modal("show");
});

$(document).on("click", ".delete-contract", function() {
  var contractId = $(this).attr("value");

  swal({
    title: "Are you sure?",
    text: "Do you want to Delete this Contract?",
    type: "warning",
    showCancelButton: true,
    confirmButtonColor: "#DD6B55",
    confirmButtonText: "Yes, Delete it!",
    cancelButtonText: "No, Cancel plz!",
    closeOnConfirm: false,
    closeOnCancel: false
  },
  function(isConfirm) {
    if (isConfirm) {
      $.ajax({
        type: "POST",
        url: "/influencer/remove_contract",
        data: { contract_id: contractId },
        dataType: "JSON",
        success:function(data){
          if(data.code == 200) {
            swal("Deleted!", "Contract has been deleted", "success")
            window.location.reload();
          }
        },
        error: function() {
          swal("error", data.response_message, "error")
        }
      });
    } else {
      swal("Cancelled", "No change in Contract", "error");
    }
  });
});

$(document).on("change", ".address-country-search", function () {
  $(this).closest("form").submit();
});

$(document).on("change", ".order-cancel-by-selection", function () {
  var userId = $(this).val()
  $.get("/get_user_details?user_id=" + userId);
});