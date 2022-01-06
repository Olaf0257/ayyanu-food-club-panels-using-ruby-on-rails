$(document).ready(function() {
  $(document).on("click", ".addcoveragearea", function(event) {
    $("#add-coverage-area").modal({ backdrop: "static", keyboard: false });
    $("#add-coverage-area").modal("show");
  })

  $(".delete_coverage_area").click(function() {
    console.log("aaaaaaaaaaaaaaaa")
    var coverage_area = $(this).attr("value")
    swal({
      title: "Are you sure?",
      text: "Do you want to delete this category !",
      type: "warning",
      showCancelButton: true,
      confirmButtonColor: "#DD6B55",
      confirmButtonText: "Yes, Delete it!",
      cancelButtonText: "No, cancel plz!",
      closeOnConfirm: false,
      closeOnCancel: false
    },
    function(isConfirm) {
      if (isConfirm) {
        $.ajax({
          type: "GET",
          url: "/delete/coverage/area",
          data: { coverage_area_id: coverage_area },
          dataType: "JSON",
          success:function(data) {
            if(data.code == 200) {
              swal("Deleted!", "Coverage Area has been deleted!", "success")
              document.getElementById("order-" + coverage_area + "").outerHTML = "";
            }
          },
          error: function() {
            swal("error", data.response_message, "error")
          }
        });
      } else {
        swal("Cancelled", "No change in Coverage Area", "error");
      }
    });
  });
});

$(document).on("change", ".district-country-select", function() {
  var country = $(".district-country-select option:selected").text();
  $.get("/districts/state_list?country=" + country);
});

$(document).on("click", ".remove-zone-area-btn", function() {
  var areaId = $(this).data("id");
  $(this).closest("div").remove();
  $(".zone-area-modal-close").addClass("zone-refresh");
  $.get("/zones/remove_area_from_zone?area_id=" + areaId);
});

$(document).on("click", ".zone-refresh", function() {
  window.location.reload();
});