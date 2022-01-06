// function delete_enterprise(id) {
//   swal({
//     title: "Are you sure?",
//     text: "Do you want to Permanently Delete this Restaurant?",
//     type: "warning",
//     showCancelButton: true,
//     confirmButtonColor: "#DD6B55",
//     confirmButtonText: "Yes, Delete It!",
//     cancelButtonText: "No, Cancel Plz!",
//     closeOnConfirm: false,
//     closeOnCancel: false
//   },
//   function(isConfirm) {
//     if (isConfirm) {
//       $.ajax({
//         type: "GET",
//         url: "/delete/enterprise/" + id,
//         dataType: "JSON",
//         success: function(data) {
//           if (data.code == 200) {
//             swal("Deleted!", "Enterprise has been deleted.", "success");
//             document.getElementById("card-"+id).outerHTML = "";
//           }
//         },
//         error: function() {
//           swal("Error", "Something went wrong", "Error")
//         }
//       });
//     } else {
//       swal("Cancelled", "No change in Enterprise", "error");
//     }
//   });
// };

// function approve_name_change(id) {
//   swal({
//     title: "Are you sure?",
//     text: "Do you want to Approve Name Change of this Restaurant?",
//     type: "warning",
//     showCancelButton: true,
//     confirmButtonColor: "#DD6B55",
//     confirmButtonText: "Yes, Approve It!",
//     cancelButtonText: "No, Cancel Plz!",
//     closeOnConfirm: false,
//     closeOnCancel: false
//   },
//   function(isConfirm) {
//     if (isConfirm) {
//       $.ajax({
//         type: "GET",
//         url: "/approve_name_change/restaurant/" + id,
//         dataType: "JSON",
//         success: function(data) {
//           if (data.code == 200) {
//             swal("Approved!", "Restaurant name change has been approved.", "success");
//             window.location.reload();
//           }
//         },
//         error: function() {
//           swal("Error", "Something went wrong", "Error")
//         }
//       });
//     } else {
//       swal("Cancelled", "No change in Restaurant", "error");
//     }
//   });
// };

// function reject_name_change(id) {
//   swal({
//     title: "Are you sure?",
//     text: "Do you want to Reject Name Change of this Restaurant?",
//     type: "warning",
//     showCancelButton: true,
//     confirmButtonColor: "#DD6B55",
//     confirmButtonText: "Yes, Reject It!",
//     cancelButtonText: "No, Cancel Plz!",
//     closeOnConfirm: false,
//     closeOnCancel: false
//   },
//   function(isConfirm) {
//     if (isConfirm) {
//       $.ajax({
//         type: "GET",
//         url: "/reject_name_change/restaurant/" + id,
//         dataType: "JSON",
//         success: function(data) {
//           if (data.code == 200) {
//             swal("Rejected!", "Restaurant name change has been rejected.", "success");
//             window.location.reload();
//           }
//         },
//         error: function() {
//           swal("Error", "Something went wrong", "Error")
//         }
//       });
//     } else {
//       swal("Cancelled", "No change in Restaurant", "error");
//     }
//   });
// };

// $(document).on("click", ".pick-all-menu-management-item", function() {
//   var checkboxes = $(".pick-menu-management-item");

//   if($(this).prop("checked")) {
//     checkboxes.prop("checked", true);
//   } else {
//     checkboxes.prop("checked", false);
//   }
// });

// $(document).on("click", ".pick-menu-management-item", function () {
//   if($(".pick-menu-management-item").length == $(".pick-menu-management-item:checked").length) {
//     $(".pick-all-menu-management-item").prop("checked", true);
//   } else {
//     $(".pick-all-menu-management-item").prop("checked", false);
//   }
// });

// $(document).on("click", ".menu-management-bulk-approve", function() {
//   if($(".pick-menu-management-item:checked").length > 0) {
//     $("#action_type").val("approve");
//     $(this).closest("form").submit();
//   } else {
//     swal("Warning", "Please Select an Item", "warning");
//   }
// });

// $(document).on("click", ".menu-management-bulk-reject", function(e) {
//   if($(".pick-menu-management-item:checked").length > 0) {
//     $("#reject_item_modal").modal("show")
//   } else {
//     swal("Warning", "Please Select an Item", "warning");
//   }
// });

// $(document).on("click", ".bulk-reject-submit", function(e) {
//   var reason = $("#bulk_reject_reason").val();

//   if($.trim(reason) == "") {
//     swal("Warning", "Please Enter the Rejection Reason", "warning");
//   } else {
//     $("#bulk_rejection_reason").val(reason);
//     $("#action_type").val("reject");
//     $(".menu-management-bulk-form").submit();
//   }
// });

// $(document).on("change", ".delivery-charge-search", function () {
//   $(this).closest("form").submit();
// });

// $(document).on("click", ".admin-change-offer-state", function () {
//   var offerid = $(this).attr("value");
//   var offerStatus = $(this).text();

//   if(offerStatus == "Deactivate") {
//     var query = "Do you want to Deactivate this offer?"
//     var confirmText = "Yes, Deactivate Offer!"
//   } else {
//     var query = "Do you want to Activate this offer?"
//     var confirmText = "Yes, Activate Offer!"
//   }

//   swal({
//     title: "Are you sure?",
//     text: query,
//     type: "warning",
//     showCancelButton: true,
//     confirmButtonColor: "#DD6B55",
//     confirmButtonText: confirmText,
//     cancelButtonText: "No, cancel plz!",
//     closeOnConfirm: false,
//     closeOnCancel: false
//   },
//   function(isConfirm) {
//     if (isConfirm) {
//       $.ajax({
//         type: "GET",
//         url: "/business/offer/status/" + offerid,
//         dataType: "JSON",
//         success:function(data){
//           if(data.code == 200) {
//             swal("success!", data.message, "success")
//             window.location.reload();
//           }
//         },
//         error: function() {
//           swal("error", data.response_message, "error")
//         }
//       });
//     } else {
//       swal("Cancelled", "No change in Offer", "error");
//     }
//   });
// });

// $(document).on("click", ".remove-menu-item-image-btn", function () {
//   var id = $(this).data("id");

//   swal({
//     title: "Are you sure?",
//     text: "Do you want to Delete this Image?",
//     type: "warning",
//     showCancelButton: true,
//     confirmButtonColor: "#DD6B55",
//     confirmButtonText: "Yes, Delete It!",
//     cancelButtonText: "No, Cancel Plz!",
//     closeOnConfirm: false,
//     closeOnCancel: false
//   },
//   function(isConfirm) {
//     if (isConfirm) {
//       $.ajax({
//         type: "GET",
//         url: "/remove_menu_item_image?id=" + id,
//         dataType: "JSON",
//         success:function(data){
//           if(data.code == 200) {
//             $(".img-tag").attr("src", "/assets/ic_placeholder.png");
//             $(".remove-menu-item-image-btn").remove();
//             swal("Deleted", "Image Removed Successfully!", "success");
//           }
//         },
//         error: function() {
//           swal("error", "Image cannot be deleted", "error")
//         }
//       });
//     } else {
//       swal("Cancelled", "No change done", "error");
//     }
//   });
// });

// $(document).on("click", ".refund-order-btn", function() {
//   $("#refund_order_modal").modal("show");
//   $("#order_id").val($(this).data("id"));
//   $(".refund-fault-row").removeClass("hide");
//   $(".no-refund-fault-row").addClass("hide");
//   $("#status").val("refund");
// });

// $(document).on("click", ".no-refund-order-btn", function() {
//   $("#refund_order_modal").modal("show");
//   $("#order_id").val($(this).data("id"));
//   $(".no-refund-fault-row").removeClass("hide");
//   $(".refund-fault-row").addClass("hide");
//   $("#status").val("no_refund");
// });

// $(document).on("change", ".ad-type-filter", function () {
//   $(this).closest("form").submit();
// });

// $(document).on("click", ".open-branch-checkbox", function() {
//   var targetRow = $(this).closest(".day-row").find(".timing-row");

//   if (targetRow.find(".open-branch-checkbox:checked").length > 0) {
//     targetRow.find(".branch-opening-time, .branch-closing-time, .add-branch-hours").removeClass("hide");
//   } else {
//     targetRow.find(".branch-opening-time, .branch-closing-time, .add-branch-hours").addClass("hide");
//   }
// });

// $(document).on("click", ".add-branch-hours", function(e) {
//   e.preventDefault();
//   var targetRow = $(this).closest(".day-row");
//   targetRow.addClass("target-row");
//   var count = targetRow.find(".timing-row").length;
//   var day = targetRow.find(".timing-row:last").attr("id");
//   $.get("/business/add_new_branch_timing?count=" + count + "&day=" + day);
// });

// $(document).on("click", ".remove-branch-timing", function() {
//   $(this).closest(".timing-row").remove();
// });

// $(document).on("change", ".coupon-restaurant-select", function (e) {
//   e.preventDefault();
//   var id = $(this).closest(".row").attr("id");
//   var restaurantId = $(this).val();
//   $.get("/influencer_coupons/branch_list?restaurant_id=" + restaurantId + "&row_id=" + id);
// });

// $(document).on("change", ".coupon-branch-select", function (e) {
//   e.preventDefault();
//   var id = $(this).closest(".row").attr("id");
//   var branchIds = $(this).val();
//   var restaurantId = $(this).closest(".row").find(".coupon-restaurant-select").val();
//   $.get("/influencer_coupons/category_list?branch_ids=" + branchIds + "&row_id=" + id + "&restaurant_id=" + restaurantId);
// });

// $(document).on("change", ".coupon-category-select", function (e) {
//   e.preventDefault();
//   var id = $(this).closest(".row").attr("id");
//   var categoryIds = $(this).val();
//   var restaurantId = $(this).closest(".row").find(".coupon-restaurant-select").val();
//   $.get("/influencer_coupons/item_list?category_ids=" + categoryIds + "&row_id=" + id + "&restaurant_id=" + restaurantId);
// });

// $(document).on("click", ".add-coupon-restaurant", function(e) {
//   e.preventDefault();
//   var countryId = $("#country_id").val();
//   $(this).closest(".row").addClass("target-row");
//   var id = $(this).closest(".row").attr("id");
//   $.get("/influencer_coupons/add_new_row?row_id=" + id + "&country_id=" + countryId);
//   $(this).addClass("hide");
// });

// $(document).on("click", ".remove-coupon-restaurant", function(e) {
//   e.preventDefault();

//   if($(".coupon-restaurant-list").length > 1) {
//     $(this).closest(".row").remove();

//     if($(".add-manual-order-item:visible").length == 0) {
//       $(".add-coupon-restaurant:last").removeClass("hide");
//     }
//   }
// });

// $(document).on("click", ".coupon-all-restaurant-checkbox", function() {
//   if($(this).is(":checked")) {
//     $(".coupon-restaurant-list").addClass("hide");
//     $(".coupon-restaurant-select").attr("required", false);
//   } else {
//     $(".coupon-restaurant-list").removeClass("hide");
//     $(".coupon-restaurant-select").attr("required", true);
//   }
// });