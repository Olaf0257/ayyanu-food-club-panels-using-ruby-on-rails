$(document).ready(function () {
  $(".edit-distance-delivery-charge").on("click", function () {
    var chargeId = $(this).data("id");
    var minDistance = $(this).data("min");
    var maxDistance = $(this).data("max");
    var charge = $(this).data("charge");
    var amount = $(this).data("amount");
    var service = $(this).data("service");
    var countryId = $(this).data("country");
    var currency = $(this).data("currency");
    $("#delivery_charge_id").val(chargeId);
    $("#edit_distance_delivery_charge_modal #min_distance").val(minDistance);
    $("#edit_distance_delivery_charge_modal #max_distance").val(maxDistance);
    $("#edit_distance_delivery_charge_modal #charge").val(charge);
    $("#edit_distance_delivery_charge_modal #min_order_amount").val(amount);
    $("#edit_distance_delivery_charge_modal #delivery_service").val(service);
    $("#edit_distance_delivery_charge_modal #country_id").val(countryId);
    $("#edit_distance_delivery_charge_modal .currency").html('('+currency+')');
  });

  $('#distance_delivery_charge_country_id').on('change', function() {
    $.ajax({
      type: "GET",
      url: "/delivery_company/get_currency",
      data: {country_id: this.value},
      dataType: "JSON",
      success:function(data){
        if(data.code==200){
          $('.currency').html('('+data.message+')')
        } else {
          $('.currency').html('BD')
        }
      },
      error: function() {
        swal("error",data.response_message,"error")
      }
    });

  });

  $('#country_id').on('change', function() {
    $.ajax({
      type: "GET",
      url: "/delivery_company/get_currency",
      data: {country_id: this.value},
      dataType: "JSON",
      success:function(data){
        if(data.code==200){
          $('.currency').html('('+data.message+')')
        } else {
          $('.currency').html('BD')
        }
      },
      error: function() {
        swal("error",data.response_message,"error")
      }
    });

  });

  $('#charge_country_id').on('change', function() {
    $.ajax({
      type: "GET",
      url: "/delivery_company/get_currency",
      data: {country_id: this.value},
      dataType: "JSON",
      success:function(data){
        if(data.code==200){
          $('.charge-currency').html('('+data.message+')')
        } else {
          $('.charge-currency').html('BD')
        }
      },
      error: function() {
        swal("error",data.response_message,"error")
      }
    });

  });
})