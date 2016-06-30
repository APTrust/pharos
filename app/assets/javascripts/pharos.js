var activate_tabs = function() {
    $('ul.nav-tabs li:first').addClass('active');
    $('ul.nav-tabs + div.tab-content div.tab-pane:first').addClass('active');
};

var dropdown = function() {
    $('.dropdown-toggle').dropdown();
};

function add_form_classes() {
    $("#tabs-2 form").addClass("search-query-form form-inline clearfix navbar-form");
    $("#tabs-1 form").addClass("search-query-form form-inline clearfix navbar-form");
}

function select_wi_tab() {
    $("#tabs-2-link").click();
}

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