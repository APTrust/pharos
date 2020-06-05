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
        if (stage != "") {
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
