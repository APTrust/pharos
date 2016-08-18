var activate_tabs = function() {
    $('ul.nav-tabs li:first').addClass('active');
    $('ul.nav-tabs + div.tab-content div.tab-pane:first').addClass('active');
};

var dropdown = function() {
    $('.dropdown-toggle').dropdown();
};

var fix_search_breadcrumb = function() {
    $("a.btn-sm").removeClass("dropdown-toggle");
    $("span.btn-sm").removeClass("btn-disabled");
}

var addClickFunctions = function() {
    var buttons = $("a.btn-sm.btn-default");
    for (var i = 0; i < buttons.length; i++) {
        buttons[i].onclick = function() {
            var href = $(this).attr("href");
            window.location.assign(href);
        }
    }
}

var addSearchComment = function() {
    var value = $("#search_field").val()
    if( value == 'file_identifier') {
        jQuery('<p/>', {
            class: "italic",
            text: "*Searching by File Identifier will bring back Generic File results. Searching by any other field will bring back Intellectual Object Results."
        }).appendTo("#search-navbar");
    }
}

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

$(document).ready(activate_tabs);
$(document).on('page:load', activate_tabs);
$(document).ready(dropdown);
$(document).on('page:load', dropdown);
$(document).ready(fix_search_breadcrumb);
$(document).on('page:load', fix_search_breadcrumb);
$(document).ready(addClickFunctions);
$(document).on('page:load', addClickFunctions);
$(document).ready(addSearchComment);
$(document).on('page:load', addSearchComment);