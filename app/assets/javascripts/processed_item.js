function selected (category, filter, newpath) {
    $("#filter-"+category+" ul li").remove();
    var parent = $("#"+category+"-parent")[0];
    $(parent).addClass("facet_limit-active");
    jQuery('<li/>').appendTo("#filter-"+category+" ul");
    jQuery('<span/>', {
        class: "facet-label"
    }).appendTo("#filter-"+category+" ul li");
    jQuery('<span/>', {
        class: "selected",
        text: filter
    }).appendTo("#filter-"+category+" ul li span");
    jQuery('<a/>', {
        class: "remove",
        href: newpath
    }).appendTo("#filter-"+category+" ul li span span");
    jQuery('<span/>', {
        class: "glyphicon glyphicon-remove"
    }).appendTo("#filter-"+category+" ul li span span a");
    $("#filter-title-"+category).click();
    $("#filter-"+category).addClass("in");
    $("#filter-title-"+category).removeClass("collapsed");

}

function callHandleSelected () {
    review_elements = $(".review");
    review_list = [];
    for(i = 0; i < review_elements.length; i++){
        if(review_elements[i].checked == true){
            review_list.push(review_elements[i].id);
        }
    }
    makeCall = confirm("Are you sure you want to mark as reviewed and/or purge these items?")
    if(makeCall == true){
        $.post('/itemresults/handle_selected', { review: review_list },
            function(data) {
                //alert(data);
            });
    }
}

function showReviewed () {
    show = $("#toggleReviewed").prop('checked');
    $.post('/itemresults/show_reviewed', { show_reviewed: show },
        function(data){

        });
}

function addClassesToBtns () {
    $("#buttons input").addClass('btn');
    $("#buttons input").addClass('btn-normal');
}