function configureDropDownLists() {
    var ddl1 = document.getElementById('object_type');
    var ddl2 = document.getElementById('search_field');
    var io_options = ['Object Identifier', 'Alternate Identifier', 'Bag Group Identifier', 'Bag Name', 'Title'];
    var gf_options = ['File Identifier', 'URI'];
    var event_options = ['Event Identifier', 'Object Identifier', 'File Identifier'];
    var wi_options = ['Object Identifier', 'File Identifier', 'Name', 'Etag'];
    var dpn_options = ['Item Identifier'];
    var listSwitch = {
        "Intellectual Objects": function () { createOptionList(ddl2, io_options); },
        "Generic Files": function () { createOptionList(ddl2, gf_options); },
        "Work Items": function () { createOptionList(ddl2, wi_options); },
        "Premis Events": function () { createOptionList(ddl2, event_options); },
        "DPN Items": function () { createOptionList(ddl2, dpn_options); }
    };
    listSwitch[ddl1.value]();
}

function createOptionList(ddl, option_list) {
    ddl.options.length = 0;
    for (var i = 0; i < option_list.length; i++) {
        createOption(ddl, option_list[i]);
    }
}

function createOption(ddl, value) {
    var opt = document.createElement('option');
    opt.value = value;
    opt.text = value;
    ddl.options.add(opt);
}

function fixSearchBreadcrumb() {
    $("a.btn-sm").removeClass("dropdown-toggle");
    $("span.btn-sm").removeClass("btn-disabled");
}

function adjustSearchField(param) {
    var ddl2 = document.getElementById('search_field');
    ddl2.value = param;
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
    var filterTitle = $("#filter-title-"+category);
    filterTitle.click();
    $("#filter-"+category).addClass("in");
    filterTitle.removeClass("collapsed");
    $("."+category+"-carat").removeClass("glyphicon-chevron-right").addClass("glyphicon-chevron-down");
}

function fixFilters() {
    var filterIds = ['access', 'action', 'event_type', 'format', 'institution', 'node', 'outcome', 'queued', 'stage', 'state', 'status', 'retry'];
    for (var i = 0; i < filterIds.length; i++) {
        var filter = $("#filter-"+filterIds[i]);
        filter.on('shown.bs.collapse', shownClickHandler());
        filter.on('hidden.bs.collapse', hiddenClickHandler());
    }
}

function shownClickHandler() {
    return function () {
        var filter_type = this.id.split('-')[1];
        $("."+filter_type+"-carat").removeClass("glyphicon-chevron-right").addClass("glyphicon-chevron-down");
    };
}

function hiddenClickHandler() {
    return function () {
        var filter_type = this.id.split('-')[1];
        $("."+filter_type+"-carat").removeClass("glyphicon-chevron-down").addClass("glyphicon-chevron-right");
    };
}