function geoloc(){
 if (navigator.geolocation){
        if (navigator.geolocation.timestamp < 50)
            alert("ok");
        else
            navigator.geolocation.getCurrentPosition(successCallback, errorCallback);
    }
    else
        alert("Votre navigateur ne prend pas en compte la géolocalisation HTML5");
}

function coordUpdate(lat, long){
        $("#GeoResults").load("/play/" + lat + '/' + long, function(responseTxt,statusTxt,xhr){

                if (statusTxt=="error")
                    alert("Error: " +xhr.status+": "+xhr.statusText)
            });
};

function successCallback(position){
    coordUpdate(position.coords.latitude, position.coords.longitude);
};  

function errorCallback(error){
            $.getJSON("http://ip-api.com/json/?callback=?", function(data) {
            coordUpdate(data['lat'], data['lon']);
        });
};