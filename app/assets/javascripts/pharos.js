function activate_tabs() {
    $('ul.nav-tabs li:first').addClass('active');
    $('ul.nav-tabs + div.tab-content div.tab-pane:first').addClass('active');
};

function dropdown() {
    $('.dropdown-toggle').dropdown();
};

function fix_search_breadcrumb() {
    $("a.btn-sm").removeClass("dropdown-toggle");
    $("span.btn-sm").removeClass("btn-disabled");
}

function addClickFunctions() {
    var buttons = $("a.btn-sm.btn-default");
    for (var i = 0; i < buttons.length; i++) {
        buttons[i].onclick = function() {
            var href = $(this).attr("href");
            window.location.assign(href);
        }
    }
}

function addSearchComment() {
    var value = $("#search_field").val()
    if( value == 'file_identifier') {
        jQuery('<p/>', {
            class: "italic",
            text: "*Searching by File Identifier will bring back Generic File results. Searching by any other field will bring back Intellectual Object Results."
        }).appendTo("#search-navbar");
    }
}

function configureDropDownLists() {
    ddl1 = document.getElementById('object_type');
    ddl2 = document.getElementById('search_field');
    var io_options = ['All Fields', 'Object Identifier', 'Alternate Identifier', 'Bag Name', 'Title'];
    var gf_options = ['All Fields', 'File Identifier', 'URI'];
    var event_options = ['All Fields', 'Object Identifier', 'File Identifier', 'Event Identifier'];
    var wi_options = ['All Fields', 'Object Identifier', 'File Identifier', 'Name', 'Etag']
    var all_options = ['All Fields', 'Object Identifier', 'File Identifier', 'Event Identifier', 'Bag Name', 'Title', 'Alternate Identifier', 'URI', 'Name', 'Etag']

    switch (ddl1.value) {
        case 'All Types':
            ddl2.options.length = 0;
            for (i = 0; i < all_options.length; i++) {
                createOption(ddl2, all_options[i]);
            }
            break;
        case 'Intellectual Objects':
            ddl2.options.length = 0;
            for (i = 0; i < io_options.length; i++) {
                createOption(ddl2, io_options[i]);
            }
            break;
        case 'Generic Files':
            ddl2.options.length = 0;
            for (i = 0; i < gf_options.length; i++) {
                createOption(ddl2, gf_options[i]);
            }
            break;
        case 'Work Items':
            ddl2.options.length = 0;
            for (i = 0; i < wi_options.length; i++) {
                createOption(ddl2, wi_options[i]);
            }
            break;
        case 'Premis Events':
            ddl2.options.length = 0;
            for (i = 0; i < event_options.length; i++) {
                createOption(ddl2, event_options[i]);
            }
            break;

    }

}

function createOption(ddl, value) {
    var opt = document.createElement('option');
    opt.value = value;
    opt.text = value;
    ddl.options.add(opt);
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
    $("."+category+"-carat").removeClass("glyphicon-chevron-right").addClass("glyphicon-chevron-down");
}

function fixFilters() {
    var filterList = ['access', 'action', 'event_type', 'fassociation', 'format', 'institution', 'oassocation', 'outcome', 'stage', 'status', 'type']
    for (var i = 0; i < filterList.length; i++) {
        $("#filter-"+filterList[i]).on('shown.bs.collapse', function () {
            $("."+filterList[i]+"-carat").removeClass("glyphicon-chevron-right").addClass("glyphicon-chevron-down");
        });
        $("#filter-"+filterList[i]).on('hidden.bs.collapse', function () {
            $("."+filterList[i]+"-carat").removeClass("glyphicon-chevron-down").addClass("glyphicon-chevron-right");
        });
    }
}

$(document).ready(function(){
    fixFilters();
    configureDropDownLists();
    activate_tabs();
    dropdown();
    fix_search_breadcrumb();
    addClickFunctions();
    addSearchComment();
});

//$(document).on('page:load', activate_tabs);
//$(document).on('page:load', dropdown);
//$(document).on('page:load', fix_search_breadcrumb);
//$(document).on('page:load', addClickFunctions);
//$(document).on('page:load', addSearchComment);