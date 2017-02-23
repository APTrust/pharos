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

function configureDropDownLists() {
    ddl1 = document.getElementById('object_type');
    ddl2 = document.getElementById('search_field');
    var io_options = ['Object Identifier', 'Alternate Identifier', 'Bag Name', 'Title'];
    var gf_options = ['File Identifier', 'URI'];
    var event_options = ['Event Identifier', 'Object Identifier', 'File Identifier'];
    var wi_options = ['Object Identifier', 'File Identifier', 'Name', 'Etag'];

    switch (ddl1.value) {
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

function adjustSearchField(param) {
    ddl2 = document.getElementById('search_field');
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
    $("#filter-title-"+category).click();
    $("#filter-"+category).addClass("in");
    $("#filter-title-"+category).removeClass("collapsed");
    $("."+category+"-carat").removeClass("glyphicon-chevron-right").addClass("glyphicon-chevron-down");
}

function plotGraph (statistics_array) {
    var options = {
        grid: {
            margin: {
                right: 20,
                left: 70,
                bottom: 20
            }
        },
        xaxis: {
            mode: "time",
            timeformat: "%m/%d/%y",
            minTickSize: [1, "day"]
        }
    };
    $.plot("#chart", [statistics_array], options);
}

function fixFilters() {
    $("#filter-access").on('shown.bs.collapse', function () {
        $(".access-carat").removeClass("glyphicon-chevron-right").addClass("glyphicon-chevron-down");
    });
    $("#filter-access").on('hidden.bs.collapse', function () {
        $(".access-carat").removeClass("glyphicon-chevron-down").addClass("glyphicon-chevron-right");
    });

    $("#filter-action").on('shown.bs.collapse', function () {
        $(".action-carat").removeClass("glyphicon-chevron-right").addClass("glyphicon-chevron-down");
    });
    $("#filter-action").on('hidden.bs.collapse', function () {
        $(".action-carat").removeClass("glyphicon-chevron-down").addClass("glyphicon-chevron-right");
    });

    $("#filter-event_type").on('shown.bs.collapse', function () {
        $(".event_type-carat").removeClass("glyphicon-chevron-right").addClass("glyphicon-chevron-down");
    });
    $("#filter-event_type").on('hidden.bs.collapse', function () {
        $(".event_type-carat").removeClass("glyphicon-chevron-down").addClass("glyphicon-chevron-right");
    });

    $("#filter-format").on('shown.bs.collapse', function () {
        $(".format-carat").removeClass("glyphicon-chevron-right").addClass("glyphicon-chevron-down");
    });
    $("#filter-format").on('hidden.bs.collapse', function () {
        $(".format-carat").removeClass("glyphicon-chevron-down").addClass("glyphicon-chevron-right");
    });

    $("#filter-institution").on('shown.bs.collapse', function () {
        $(".institution-carat").removeClass("glyphicon-chevron-right").addClass("glyphicon-chevron-down");
    });
    $("#filter-institution").on('hidden.bs.collapse', function () {
        $(".institution-carat").removeClass("glyphicon-chevron-down").addClass("glyphicon-chevron-right");
    });

    $("#filter-institution").on('shown.bs.collapse', function () {
        $(".institution-carat").removeClass("glyphicon-chevron-right").addClass("glyphicon-chevron-down");
    });
    $("#filter-institution").on('hidden.bs.collapse', function () {
        $(".institution-carat").removeClass("glyphicon-chevron-down").addClass("glyphicon-chevron-right");
    });

    $("#filter-outcome").on('shown.bs.collapse', function () {
        $(".outcome-carat").removeClass("glyphicon-chevron-right").addClass("glyphicon-chevron-down");
    });
    $("#filter-outcome").on('hidden.bs.collapse', function () {
        $(".outcome-carat").removeClass("glyphicon-chevron-down").addClass("glyphicon-chevron-right");
    });

    $("#filter-stage").on('shown.bs.collapse', function () {
        $(".stage-carat").removeClass("glyphicon-chevron-right").addClass("glyphicon-chevron-down");
    });
    $("#filter-stage").on('hidden.bs.collapse', function () {
        $(".stage-carat").removeClass("glyphicon-chevron-down").addClass("glyphicon-chevron-right");
    });

    $("#filter-status").on('shown.bs.collapse', function () {
        $(".status-carat").removeClass("glyphicon-chevron-right").addClass("glyphicon-chevron-down");
    });
    $("#filter-status").on('hidden.bs.collapse', function () {
        $(".status-carat").removeClass("glyphicon-chevron-down").addClass("glyphicon-chevron-right");
    });

    $("#filter-node").on('shown.bs.collapse', function () {
        $(".node-carat").removeClass("glyphicon-chevron-right").addClass("glyphicon-chevron-down");
    });
    $("#filter-node").on('hidden.bs.collapse', function () {
        $(".node-carat").removeClass("glyphicon-chevron-down").addClass("glyphicon-chevron-right");
    });

    $("#filter-queued").on('shown.bs.collapse', function () {
        $(".queued-carat").removeClass("glyphicon-chevron-right").addClass("glyphicon-chevron-down");
    });
    $("#filter-queued").on('hidden.bs.collapse', function () {
        $(".queued-carat").removeClass("glyphicon-chevron-down").addClass("glyphicon-chevron-right");
    });
}

$( function() {

    function addUser() {
        var valid = true;
        allFields.removeClass( "ui-state-error" );

        valid = valid && checkLength( name, "username", 3, 16 );
        valid = valid && checkLength( email, "email", 6, 80 );
        valid = valid && checkLength( password, "password", 5, 16 );

        valid = valid && checkRegexp( name, /^[a-z]([0-9a-z_\s])+$/i, "Username may consist of a-z, 0-9, underscores, spaces and must begin with a letter." );
        valid = valid && checkRegexp( email, emailRegex, "eg. ui@jquery.com" );
        valid = valid && checkRegexp( password, /^([0-9a-zA-Z])+$/, "Password field only allow : a-z 0-9" );

        if ( valid ) {
            $( "#users tbody" ).append( "<tr>" +
                "<td>" + name.val() + "</td>" +
                "<td>" + email.val() + "</td>" +
                "<td>" + password.val() + "</td>" +
                "</tr>" );
            dialog.dialog( "close" );
        }
        return valid;
    }



    form = dialog.find( "form" ).on( "submit", function( event ) {
        event.preventDefault();
        addUser();
    });
} );

function restoreRequeueSetUp(){
    dialog = $("#dialog-form-restore").dialog({
        autoOpen: false,
        height: 400,
        width: 350,
        modal: true,
        buttons: {
            "Requeue": restoreResponse(),
            Cancel: function() {
                dialog.dialog("close");
            }
        },
        close: function() {
            form[ 0 ].reset();
            allFields.removeClass("ui-state-error");
        }
    });
    $("#requeue_restore").button().on("click", function() {
        dialog.dialog("open");
    });
}

function ingestRequeueSetUp(){
    dialog = $("#dialog-form-ingest").dialog({
        autoOpen: false,
        height: 400,
        width: 350,
        modal: true,
        buttons: {
            "Requeue": ingestResponse(),
            Cancel: function() {
                dialog.dialog("close");
            }
        },
        close: function() {
            form[ 0 ].reset();
            allFields.removeClass("ui-state-error");
        }
    });
    $("#requeue_ingest").button().on("click", function() {
        dialog.dialog("open");
    });
}

function dpnRequeueSetUp(){
    dialog = $("#dialog-form-dpn").dialog({
        autoOpen: false,
        height: 400,
        width: 350,
        modal: true,
        buttons: {
            "Requeue": dpnResponse(),
            Cancel: function() {
                dialog.dialog("close");
            }
        },
        close: function() {
            form[ 0 ].reset();
            allFields.removeClass("ui-state-error");
        }
    });
    $("#requeue_dpn").button().on("click", function() {
        dialog.dialog("open");
    });
}

function restoreResponse(){

}

function ingestResponse(){

}

function dpnResponse(){

}

$(document).ready(function(){
    fixFilters();
    activate_tabs();
    dropdown();
    fix_search_breadcrumb();
    addClickFunctions();
});