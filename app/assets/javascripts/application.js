// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery/jquery-2.1.1.js
//= require sparkline/jquery.sparkline.min.js
//= require sweetalert2
//= require sweet-alert2-rails
//= require chartjs/Chart.min.js
//= require chartist/chartist.min.js
//= require imagekit.js
//= require order.js
//= require select2

function upload_image_on_imagekit(image){
  var imageURL = imagekit.url({
    path: "/default-image.jpg",
    urlEndpoint: "https://ik.imagekit.io/your_imagekit_id/endpoint/",
    transformation: [{
      "height": "300",
      "width": "400"
    }]
  });
}

$(document).ready(function() {
  var screenWidth = $(window).width();
  var count = 0;

  if (screenWidth >= 1200) {
    count = 6;
  } else if (screenWidth >= 992) {
    count = 4;
  } else if (screenWidth >= 768) {
    count = 3;
  } else if (screenWidth < 768) {
    count = 2;
  }

  $(".carousel .item").each(function() {
    var i = $(this).next();
    i.length || (i = $(this).siblings(":first")),
    i.children(":first-child").clone().appendTo($(this));
    for (var n = 0; n < (count - 2); n++)(i = i.next()).length ||
    (i = $(this).siblings(":first")),
    i.children(":first-child").clone().appendTo($(this))
  })
});

function openNav() {
  $("#mySidenav").css("width", "200px");
}

function closeNav() {
  $("#mySidenav").css("width", "0");
}

function autocomplete_area(inp, arr) {
  var currentFocus;
  inp.addEventListener("input", function(e) {
    var a, b, i, val = this.value;
    closeAllLists();
    if (!val) { return false;}
    currentFocus = -1;
    a = document.createElement("DIV");
    a.setAttribute("id", this.id + "autocomplete-list");
    a.setAttribute("class", "autocomplete-items");
    this.parentNode.appendChild(a);

    for (i = 0; i < arr.length; i++) {
      if (arr[i].substr(0, val.length).toUpperCase() == val.toUpperCase()) {
        b = document.createElement("DIV");
        b.innerHTML = "<strong>" + arr[i].substr(0, val.length) + "</strong>";
        b.innerHTML += arr[i].substr(val.length);
        b.innerHTML += '<input type="hidden" value="' + arr[i] + '">';
        b.addEventListener("click", function(e) {
          inp.value = this.getElementsByTagName("input")[0].value;
          closeAllLists();
        });
        a.appendChild(b);
      }
    }
  });

  inp.addEventListener("keydown", function(e) {
    var x = document.getElementById(this.id + "autocomplete-list");
    if (x) x = x.getElementsByTagName("div");

    if (e.keyCode == 40) {
      currentFocus++;
      addActive(x);
    } else if (e.keyCode == 38) {
      currentFocus--;
      addActive(x);
    } else if (e.keyCode == 13) {
      e.preventDefault();
      if (currentFocus > -1) {
        if (x) x[currentFocus].click();
      }
    }
  });

  function addActive(x) {
    if (!x) return false;
    removeActive(x);
    if (currentFocus >= x.length) currentFocus = 0;
    if (currentFocus < 0) currentFocus = (x.length - 1);
    x[currentFocus].classList.add("autocomplete-active");
  }

  function removeActive(x) {
    for (var i = 0; i < x.length; i++) {
      x[i].classList.remove("autocomplete-active");
    }
  }

  function closeAllLists(elmnt) {
    var x = document.getElementsByClassName("autocomplete-items");
    for (var i = 0; i < x.length; i++) {
      if (elmnt != x[i] && elmnt != inp) {
        x[i].parentNode.removeChild(x[i]);
      }
    }
  }

  document.addEventListener("click", function (e) {
    closeAllLists(e.target);
  });
}

$(document).on("click", ".branch-menu-expand", function () {
  if($(this).find(".fa-minus-circle").is(":visible")) {
    $(this).closest("div").find("ul").slideUp(600);
    $(this).find(".fa-minus-circle").addClass("hide");
    $(this).find(".fa-plus-circle").removeClass("hide");
  } else {
    $(this).closest("div").find("ul").slideDown(600);
    $(this).find(".fa-plus-circle").addClass("hide");
    $(this).find(".fa-minus-circle").removeClass("hide");
  }
});

function copyReferralCode() {
  var temp = $("<input>");
  $("body").append(temp);
  temp.val($("#referral_code_link").val()).select();
  document.execCommand("copy");
  temp.remove();
  swal("Success", "Referral link copied!", "success")
}

$(document).on("click", ".point-details-link", function () {
  var branchId = $(this).data("id");
  $.get("/customer/point_details?branch_id=" + branchId)
});

$(document).on("click", ".party-point-details-link", function () {
  var userId = $(this).data("user");
  var restaurantId = $(this).data("restaurant");
  $.get("/customer/party_points_details?user_id=" + userId + "&restaurant_id=" + restaurantId);
});

$(document).on("click", ".buy-party-points-btn", function () {
  $("#add_card_details_modal").modal("show");
});

$(document).on("click", ".order-details-link", function (e) {
  e.preventDefault();
  var orderId = $(this).data("id");
  $.get("/customer/order_details?order_id=" + orderId)
});

$(document).on("click", ".rating-submit-btn", function (e) {
  e.preventDefault();
  var branchId = $("#rating_branch_id").val();
  var userId = $("#user_id").val();
  var review = $("#review").val();

  if($.trim(review) === "") {
    swal("Error", "Please enter review", "error")
  } else {
    $.post("/customer/submit_branch_rating?branch_id=" + branchId + "&user_id=" + userId + "&review=" + review);
  }
});

$(document).on("click", ".club-sub-category-section label", function () {
  var userId = $(this).data("user");
  var categoryId = $(this).data("id");

  if($(this).find(".club-sub-category-checkbox").is(":checked")) {
    swal("Success", "Club Category Successfully Joined !", "success")
    $.get("/customer/add_user_club?status=join&user_id=" + userId + "&category_id=" + categoryId)
  } else {
    swal("Success", "Club Category Successfully Removed", "success")
    $.get("/customer/add_user_club?status=unjoin&user_id=" + userId + "&category_id=" + categoryId)
  }
});

$(document).on("click", ".new-dashboard-address", function (e) {
  e.preventDefault();
  $.get("/customer/new_address");
});

$(document).on("click", ".new-guest-address-btn", function (e) {
  e.preventDefault();
  $("#new_guest_address_modal").modal("show");
});

$(document).on("click", ".edit-guest-address-btn", function (e) {
  e.preventDefault();
  var addressId = $(this).data("id");
  $.get("/customer/edit_guest_address?address_id=" + addressId);
});

$(document).on("click", ".edit-dashboard-address", function (e) {
  e.preventDefault();
  var addressId = $(this).data("id");
  $.get("/customer/edit_address?address_id=" + addressId);
});

$(document).on("click", ".remove-dashboard-address", function (e) {
  e.preventDefault();
  var id = $(this).data("id");
  var targetBox = $(this).closest(".featured-restaurant-box");

  swal({
    title: "Are you sure?",
    text: "Do you want to Permanently Delete this Address?",
    type: "warning",
    showCancelButton: true,
    confirmButtonColor: "#DD6B55",
    confirmButtonText: "Yes, Delete It!",
    cancelButtonText: "No, Cancel Plz!",
    closeOnConfirm: false,
    closeOnCancel: false
  },
  function(isConfirm) {
    if (isConfirm) {
      $.ajax({
        type: "POST",
        url: "/api/v1/remove/address?address_id=" + id,
        dataType: "JSON",
        success: function(data) {
          if (data.code == 200) {
            swal("Deleted!", "Address has been deleted", "success");
            targetBox.remove();
          }
        },
        error: function() {
          swal("Error", "Something went wrong", "Error")
        }
      });
    } else {
      swal("Cancelled", "No change in Address", "error");
    }
  });
});

$(document).on("click", ".show-delivery-map", function() {
  $("#delivery_area_modal").modal({ backdrop: "static", keyboard: false });
  $("#delivery_area_modal").modal("show");
  initialize();
});

function showPosition(position) {
  $("#latitude").val(position.coords.latitude);
  $("#longitude").val(position.coords.longitude);
  $("#address").prop("required", false);
}

$(document).on("click", ".web-suggest-restaurant-btn", function (e) {
  e.preventDefault();
  var branchId = $(this).data("branch");
  var areaId = $(this).data("area");
  var userId = $(this).data("user");

  swal({
    title: "Are you sure?",
    text: "Do you want this Restaurant to be added to Food Club?",
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
        type: "POST",
        url: "/api/v1/web/suggest/restaurant?branch_id=" + branchId + "&area_id=" + areaId + "&user_id=" + userId + "&description=Please open this restaurant to this area",
        dataType: "JSON",
        success: function(data) {
          if (data.code == 200) {
            swal("Success!", "Your suggestion has been submited.", "success");
          }
        },
        error: function() {
          swal("Error", "Something went wrong", "Error")
        }
      });
    } else {
      swal("Cancelled", "No change done.", "error");
    }
  });
});

$(document).on("click", ".dine-in-order-btn", function (e) {
  e.preventDefault();
  var tableNumber = $("#table_number").val();
  var guestToken = $(this).data("guest");

  if ($("#payment_cash").is(":checked")) {
    var paymentType = "postpaid";
  } else if($("#payment_online").is(":checked")) {
    var paymentType = "prepaid";
  } else {
    var paymentType = "card_machine";
  }

  if ($("#order_type_dine_in").is(":checked")) {
    var orderType = "dine_in";
  } else {
    var orderType = "takeaway";
  }

  if($.trim(tableNumber) == "" && orderType == "dine_in") {
    swal("Warning", "Please Enter the Table Number", "warning");
  } else {
    swal({
      title: "Are you sure?",
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
        swal({
          html: true,
          title: "Placing Order...",
          text: "<center><img src='/assets/rest-loading.gif' width='30%'></center>",
          showConfirmButton: false
        });

        $.ajax({
          type: "POST",
          url: "/customer/place_dine_in_order?guest_token=" + guestToken + "&table_number=" + tableNumber + "&order_mode=" + paymentType + "&order_type=" + orderType,
          dataType: "JSON",
          success: function(data) {
            if (data.code == 200) {
              swal("Success!", "Order Placed Successfully.", "success");
              window.location.reload();
            }
          },
          error: function() {
            swal("Error", "Something went wrong", "Error")
          }
        });
      } else {
        swal("Cancelled", "No change done.", "error");
      }
    });
  }
});