$(document).ready(function() {
  if($(".order-list-inner li").length == 0) {
    $(".checkout-btn").addClass("hide");
  } else {
    $(".checkout-btn").removeClass("hide");
  }

  $(".order-countdown").each(function() {
    var target = $(this);

    var timer2 = $(this).text();
    var interval = setInterval(function() {
      var timer = timer2.split(":");
      var minutes = parseInt(timer[0], 10);
      var seconds = parseInt(timer[1], 10);
      --seconds;
      minutes = (seconds < 0) ? --minutes : minutes;

      if (minutes < 0) {
        target.html("0:00");
        return false;
      } else {
        seconds = (seconds < 0) ? 59 : seconds;
        seconds = (seconds < 10) ? "0" + seconds : seconds;
        target.html(minutes + ":" + seconds);
        timer2 = minutes + ':' + seconds;
      }
    }, 1000);
  });
});

$(document).on("click", ".order-item-details-btn", function (e) {
  e.preventDefault();
  var itemId = $(this).data("id");
  var areaId = $("#area_id").val();
  $.get("/customer/order_item_details?item_id=" + itemId + "&area_id=" + areaId);
});

$(document).on("click", "#order_item_details_modal .increment-item-count", function () {
  var itemId = $(this).data("id");
  var count = parseInt($(this).closest("span").prev().text());
  $(this).closest("span").prev().text(count + 1);
  $.get("/customer/add_order_item?item_id=" + itemId + "&qty=" + (count + 1));
});

$(document).on("click", "#order_item_details_modal .decrement-item-count", function () {
  var itemId = $(this).data("id");
  var count = parseInt($(this).closest("span").next().text());

  if(count > 1) {
    $(this).closest("span").next().text(count - 1);
    $.get("/customer/deduct_order_item?item_id=" + itemId + "&qty=" + (count - 1));
  }
});

$(document).on("click", "#order_item_details_modal .addon-item-checkbox", function () {
  var itemId = $(this).data("id");
  var menuId = $(this).data("item");

  if($(this).is(":checked")) {
    $.get("/customer/add_addon_item?item_id=" + itemId + "&menu_item_id=" + menuId);
  } else {
    $.get("/customer/deduct_addon_item?item_id=" + itemId + "&menu_item_id=" + menuId);
  }
});

$(document).on("click", "#order_item_details_modal .add-to-cart-btn", function (e) {
  var flag = true;

  $(".addon-category-list").each(function () {
    var minQty = parseInt($(this).data("min"));
    var maxQty = parseInt($(this).data("max"));
    var addonCount = $(this).find(".addon-item-checkbox:checked").length;

    if((addonCount < minQty) || (addonCount > maxQty)) {
      e.preventDefault();
      $(this).find(".min-max-error").text("Select Minimum: " + minQty + " and Maximum: " + maxQty + " Addons")
      flag = false;
    } else {
      $(this).find(".min-max-error").text("");
    }
  });

  if(flag) {
    var userId = $("#order_item_details_modal #order_user_id").val();
    var itemId = $("#order_item_details_modal #order_item_id").val();
    var branchId = $("#order_item_details_modal #order_branch_id").val();
    var areaId = $("#order_item_details_modal #order_area_id").val();
    var desc = $("#order_item_details_modal #special_request").val();
    var qty = $("#order_item_details_modal .item-count").text();
    var guestToken = $("#order_item_details_modal #guest_token").val();
    var addonItemIds = [];

    $(".addon-item-checkbox:checked").each(function() {
      addonItemIds.push($(this).data("id"));
    });

    $.post("/customer/add_items_to_cart?item_id=" + itemId + "&user_id=" + userId + "&branch_id=" + branchId + "&area_id=" + areaId + "&description=" + desc + "&quantity=" + qty + "&item_addons=" + addonItemIds + "&guest_token=" + guestToken);
    $("#order_item_details_modal").modal("hide");
  }
});

$(document).on("click", ".order-list-inner .increment-item-count", function () {
  $(this).closest("li").addClass("target-li");
  var itemId = $(this).data("id");
  var count = parseInt($(this).closest("span").prev().text());
  $(this).closest("span").prev().text(count + 1);
  $.get("/customer/add_order_item?item_id=" + itemId + "&qty=" + (count + 1) + "&checkout=true");
});

$(document).on("click", ".order-list-inner .decrement-item-count", function () {
  $(this).closest("li").addClass("target-li");
  var itemId = $(this).data("id");
  var count = parseInt($(this).closest("span").next().text());

  if(count > 1) {
    $(this).closest("span").next().text(count - 1);
    $.get("/customer/deduct_order_item?item_id=" + itemId + "&qty=" + (count - 1) + "&checkout=true");
  }
});

$(document).on("click", ".order-list-inner .remove-cart-item", function () {
  $(this).closest("li").addClass("target-li");
  var itemId = $(this).data("id");
  $.get("/customer/remove_cart_item?item_id=" + itemId);
});

$(document).on("click", ".place-order-btn", function () {
  if ($(".online-radio").is(":checked") && parseFloat($(".chargeable-amount").text()) > 0) {
    $("#add_card_details_modal").modal("show");
  } else {
    swal({
      title: "Place Order?",
      text: "Do you want to Place Order?",
      type: "warning",
      showCancelButton: true,
      confirmButtonColor: "#DD6B55",
      confirmButtonText: "Yes",
      cancelButtonText: "No",
      closeOnConfirm: false,
      closeOnCancel: false
    },
    function(isConfirm) {
      if (isConfirm) {
        var addressId = $(".address-selection:checked").val();
        $.get("/customer/send_otp?address_id=" + addressId);
      } else {
        swal("Cancelled", "Order not placed", "error");
      }
    });
  }
});

$(document).on("click", ".verify-order-otp-submit-button", function () {
  var otp = $("#otp").val();
  var userId = $("#otp_user_id").val();
  $.post("/customer/verify_otp?otp=" + otp + "&user_id=" + userId);
});

$(document).on("click", ".mail-order-payment-link-btn", function () {
  swal({
    title: "Mail Payment Link?",
    text: "Do you want to Mail Link to User?",
    type: "warning",
    showCancelButton: true,
    confirmButtonColor: "#DD6B55",
    confirmButtonText: "Yes",
    cancelButtonText: "No",
    closeOnConfirm: false,
    closeOnCancel: false
  },
  function(isConfirm) {
    if (isConfirm) {
      var redeem = $("#redeem").val();
      var addressId = $(".address-selection:checked").val();
      var userId = $("#user_id").val();
      var note = $("#delivery_request").val();

      swal({
        html: true,
        title: "Please Wait...",
        text: "<center><img src='/assets/rest-loading.gif' width='30%'></center>",
        showConfirmButton: false
      });

      $.ajax({
        type: "POST",
        url: "/customer/mail_order_payment_link?is_redeem=" + redeem + "&address_id=" + addressId + "&user_id=" + userId + "&note=" + note,
        dataType: "JSON",
        success: function(data) {
          if (data.code == 200) {
            swal("Success", "Mail Sent Successfully!", "success")
            window.location = "/";
          }
        },
        error: function() {
          swal("Error", data.message, "error")
        }
      });
    } else {
      swal("Cancelled", "Mail not sent", "error");
    }
  });
});

$(document).on("click", ".my-points-radio", function () {
  if($(".address-selection").length > 0) {
    var addressId= $(".address-selection:checked").val();
    var couponCode = $("#coupon_code").val();

    if($(this).is(":checked")) {
      window.location = "/customer/cart_item_list?my_points=true&address_id=" + addressId + "&coupon_code=" + couponCode;
    } else {
      window.location = "/customer/cart_item_list?address_id=" + addressId + "&coupon_code=" + couponCode;
    }
  } else {
    if($(this).is(":checked")) {
      window.location = "/customer/cart_item_list?my_points=true&coupon_code=" + couponCode;
    } else {
      window.location = "/customer/cart_item_listcoupon_code=" + couponCode;
    }
  }
});

$(document).on("change", ".address-selection", function () {
  var addressId= $(this).val();
  var couponCode = $("#coupon_code").val();

  if($(".my-points-radio").length > 0 && $(".my-points-radio").is(":checked")) {
    window.location = "/customer/cart_item_list?my_points=true&address_id=" + addressId+ "&coupon_code=" + couponCode;
  } else {
    window.location = "/customer/cart_item_list?address_id=" + addressId+ "&coupon_code=" + couponCode;
  }
});

$(document).on("click", ".add-favorite-branch-btn", function () {
  var target = $(this);
  var branchId = $(this).data("branch");
  var userId = $(this).data("user");

  swal({
    title: "Are you sure?",
    text: "Do you want to add this Restautant as Favorite?",
    type: "warning",
    showCancelButton: true,
    confirmButtonColor: "#DD6B55",
    confirmButtonText: "Yes",
    cancelButtonText: "No",
    closeOnConfirm: false,
    closeOnCancel: false
  },
  function(isConfirm) {
    if (isConfirm) {
      $.ajax({
        type: "GET",
        url: "/customer/add_favorite_branch?branch_id=" + branchId + "&user_id=" + userId,
        dataType: "JSON",
        success: function(data) {
          if (data.code == 200) {
            swal("Success!", "Restaurant marked as Favorite", "success");
            target.removeClass("fa-heart-o add-favorite-branch-btn").addClass("fa-heart remove-favorite-branch-btn");
          }
        },
        error: function() {
          swal("Error", "Something went wrong", "Error")
        }
      });
    } else {
      swal("Cancelled", "No change done", "error");
    }
  });
});

$(document).on("click", ".remove-favorite-branch-btn", function () {
  var target = $(this);
  var branchId = $(this).data("branch");
  var userId = $(this).data("user");

  swal({
    title: "Are you sure?",
    text: "Do you want to remove this Restautant as Favorite?",
    type: "warning",
    showCancelButton: true,
    confirmButtonColor: "#DD6B55",
    confirmButtonText: "Yes",
    cancelButtonText: "No",
    closeOnConfirm: false,
    closeOnCancel: false
  },
  function(isConfirm) {
    if (isConfirm) {
      $.ajax({
        type: "GET",
        url: "/customer/remove_favorite_branch?branch_id=" + branchId + "&user_id=" + userId,
        dataType: "JSON",
        success: function(data) {
          if (data.code == 200) {
            swal("Success!", "Restaurant removed as Favorite", "success");
            target.removeClass("fa-heart remove-favorite-branch-btn").addClass("fa-heart-o add-favorite-branch-btn");
          }
        },
        error: function() {
          swal("Error", "Something went wrong", "Error")
        }
      });
    } else {
      swal("Cancelled", "No change done", "error");
    }
  });
});

$(document).on("click", ".reorder-items-btn", function (e) {
  e.preventDefault();
  var orderId = $(this).data("id");

  swal({
    title: "Are you sure?",
    text: "Do you want to Reorder These Items?",
    type: "warning",
    showCancelButton: true,
    confirmButtonColor: "#DD6B55",
    confirmButtonText: "Yes",
    cancelButtonText: "No",
    closeOnConfirm: false,
    closeOnCancel: false
  },
  function(isConfirm) {
    if (isConfirm) {
      $.ajax({
        type: "GET",
        url: "/customer/reorder_items?order_id=" + orderId,
        dataType: "JSON",
        success: function(data) {
          if (data.code == 200) {
            swal("Success!", "Items Successfully Added to Cart!", "success");
            window.location.href = "/customer/cart_item_list";
          } else {
            swal("Warning", data.message, "warning");
          }
        },
        error: function() {
          swal("Error", "Cant Reorder", "error");
        }
      });
    } else {
      swal("Cancelled", "No change done", "error");
    }
  });
});

$(document).on("click", ".validate-coupon-code", function () {
  var code = $("#coupon_code_input").val();
  var userId = $("#user_id").val();

  $.ajax({
    type: "POST",
    url: "/api/v1/cart/apply/coupon?coupon_code=" + code + "&cart_user_id=" + userId,
    dataType: "JSON",
    success: function(data) {
      if (data.code == 200) {
        swal("Success!", "Coupon Applied Successfully!", "success");
        window.location.href = "/customer/cart_item_list?coupon_code=" + code;
      } else {
        swal("Warning", data.message, "warning");
        window.location.href = "/customer/cart_item_list?coupon_code=";
      }
    },
    error: function() {
      swal("Error", "Cant Apply Coupon Code", "error");
    }
  });
});