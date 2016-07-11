function like(id){
    $("#like").load("/like/" + id, function(responseTxt,statusTxt,xhr){

                if (statusTxt=="error")
                    alert("Error: " +xhr.status+": "+xhr.statusText)
            });
};