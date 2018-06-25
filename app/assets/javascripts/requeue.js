function restoreRequeue(){
    $('#restore_form').removeClass('hidden');
    $('#restore_form_submit').on("click", function() {
        var checked = '';
        if ($('#state_item').is(':checked')) {
            checked = 'true';
        } else {
            checked = 'false';
        }
        var id = $('#work_item_id').text();
        $.get('/items/'+id+'/requeue', {delete_state_item: checked},
            function(data) {
                alert('Item has been requeued.');
            });
    });
    $('#restore_form_cancel').on("click", function() {
        $('#restore_form').addClass('hidden');
    });
}

function ingestRequeue(){
    $('#ingest_form').removeClass('hidden');
    $('#ingest_form_submit').on("click", function() {
        var stage = $('input[name="stage"]:checked').val();
        if (stage == "Fetch" || stage == "Store" || stage == "Record") {
            if (!$('#ingest_error').hasClass('hidden')) {
                $('#ingest_error').addClass('hidden');
            }
            var id = $('#work_item_id').text();
            $.get('/items/'+id+'/requeue', {item_stage: stage},
                function(data) {
                    alert('Item has been requeued.');
                });
        } else {
            $('#ingest_error').removeClass('hidden');
        }
    });
    $('#ingest_form_cancel').on("click", function() {
        $('#ingest_form').addClass('hidden');
    });
}

function dpnRequeue() {
    $('#dpn_form').removeClass('hidden');
    $('#dpn_form_submit').on("click", function () {
        var stage = $('input[name="stage"]:checked').val();
        if (stage == "Package" || stage == "Store" || stage == "Record") {
            if (!$('#ingest_error').hasClass('hidden')) {
                $('#ingest_error').addClass('hidden');
            }
            var id = $('#work_item_id').text();
            $.get('/items/' + id + '/requeue', {item_stage: stage},
                function (data) {
                    alert('Item has been requeued.');
                });
        } else {
            $('#dpn_error').removeClass('hidden');
        }
    });
    $('#dpn_form_cancel').on("click", function () {
        $('#dpn_form').addClass('hidden');
    });
}

function dpnItemRequeue() {
    $('#dpn_item_form').removeClass('hidden');
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
            $.get('/dpn_items/' + id + '/requeue', {task: task, delete_state_item: checked},
                function (data) {
                    alert('DPN Item has been requeued.');
                });
        } else {
            $('#dpn_item_error').removeClass('hidden');
        }
    });
    $('#dpn_item_form_cancel').on("click", function () {
        $('#dpn_item_form').addClass('hidden');
    });
}