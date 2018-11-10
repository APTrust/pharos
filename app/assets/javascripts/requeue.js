function restoreRequeue(){
    $('#restore_form').removeClass('hidden');
    $('#requeue-btn').addClass('hidden');
    $('#restore_form_submit').on("click", function() {
        var checked = '';
        if ($('#state_item').is(':checked')) {
            checked = 'true';
        } else {
            checked = 'false';
        }
        var id = $('#work_item_id').text();
        $.get('/items/'+id+'/requeue', {delete_state_item: checked});
    });
    $('#restore_form_cancel').on("click", function() {
        $('#restore_form').addClass('hidden');
        $('#requeue-btn').removeClass('hidden');
    });
}

function glacierRestoreRequeue(){
    $('#glacier_restore_form').removeClass('hidden');
    $('#requeue-btn').addClass('hidden');
    $('#glacier_restore_form_submit').on("click", function() {
        var checked = '';
        if ($('#state_item').is(':checked')) {
            checked = 'true';
        } else {
            checked = 'false';
        }
        var id = $('#work_item_id').text();
        $.get('/items/'+id+'/requeue', {delete_state_item: checked});
    });
    $('#glacier_restore_form_cancel').on("click", function() {
        $('#glacier_restore_form').addClass('hidden');
        $('#requeue-btn').removeClass('hidden');
    });
}

function ingestRequeue(){
    $('#ingest_form').removeClass('hidden');
    $('#requeue-btn').addClass('hidden');
    $('#ingest_form_submit').on("click", function() {
        var stage = $('input[name="stage"]:checked').val();
        if (stage == "Fetch" || stage == "Store" || stage == "Record") {
            if (!$('#ingest_error').hasClass('hidden')) {
                $('#ingest_error').addClass('hidden');
            }
            var id = $('#work_item_id').text();
            $.get('/items/'+id+'/requeue', { item_stage: stage },
                function(data) {
                    window.location.replace(id);
                });
        } else {
            $('#ingest_error').removeClass('hidden');
        }
    });
    $('#ingest_form_cancel').on("click", function() {
        $('#ingest_form').addClass('hidden');
        $('#requeue-btn').removeClass('hidden');
    });
}

function dpnRequeue() {
    $('#dpn_form').removeClass('hidden');
    $('#requeue-btn').addClass('hidden');
    $('#dpn_form_submit').on("click", function () {
        var stage = $('input[name="stage"]:checked').val();
        if (stage == "Package" || stage == "Store" || stage == "Record") {
            if (!$('#ingest_error').hasClass('hidden')) {
                $('#ingest_error').addClass('hidden');
            }
            var id = $('#work_item_id').text();
            $.get('/items/' + id + '/requeue', {item_stage: stage});
        } else {
            $('#dpn_error').removeClass('hidden');
        }
    });
    $('#dpn_form_cancel').on("click", function () {
        $('#dpn_form').addClass('hidden');
        $('#requeue-btn').removeClass('hidden');
    });
}

function dpnItemRequeue() {
    $('#dpn_item_form').removeClass('hidden');
    $('#requeue-btn').addClass('hidden');
    $('#dpn_item_form_submit').on("click", function () {
        var checked = '';
        if ($('#dpn_state_item').is(':checked')) {
            checked = 'true';
        } else {
            checked = 'false';
        }
        var task = $('input[name="task"]:checked').val();
        if (task == "copy" || task == "validation" || task == "store" || task == 'package' || task == 'record') {
            if (!$('#dpn_item_error').hasClass('hidden')) {
                $('#dpn_item_error').addClass('hidden');
            }
            var id = $('#dpn_item_id').text();
            $.get('/dpn_items/' + id + '/requeue', {task: task, delete_state_item: checked});
        } else {
            $('#dpn_item_error').removeClass('hidden');
        }
    });
    $('#dpn_item_form_cancel').on("click", function () {
        $('#dpn_item_form').addClass('hidden');
        $('#requeue-btn').removeClass('hidden');
    });
}

function dpnItemFixityRequeue() {
    $('#dpn_item_fixity_form').removeClass('hidden');
    $('#requeue-btn').addClass('hidden');
    $('#dpn_item_fixity_form_submit').on("click", function () {
        var stage = $('input[name="stage"]:checked').val();
        if (stage == "requested" || stage == "validate" || stage == "available_in_s3") {
            if (!$('#dpn_item_fixity_error').hasClass('hidden')) {
                $('#dpn_item_fixity_error').addClass('hidden');
            }
            var id = $('#dpn_item_id').text();
            $.get('/dpn_items/' + id + '/requeue', {stage: stage});
        } else {
            $('#dpn_item_fixity_error').removeClass('hidden');
        }
    });
    $('#dpn_item_fixity_form_cancel').on("click", function () {
        $('#dpn_item_fixity_form').addClass('hidden');
        $('#requeue-btn').removeClass('hidden');
    });
}