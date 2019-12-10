$(document).ready(function() {

    var showTokenForm = function() {
        $('.auth-ot').fadeOut(function() {
            $('.auth-token').fadeIn('slow');
        });
    };

    var triggerSMSToken = function() {
        $.get('/authy/send_token');
    };

    var checkForOneTouch = function() {
        $.get('/authy/status', function(data) {
            if (data === 'approved') {
                window.location.href = '/account';
            } else if (data === 'denied') {
                showTokenForm();
                triggerSMSToken();
            } else {
                setTimeout(checkForOneTouch, 2000);
            }
        });
    };

    var attemptOneTouchVerification = function(form) {
        $.post('/sessions', form, function(data) {
            $('#authy-modal').modal({backdrop:'static'},'show');
            if (data.success) {
                $('.auth-ot').fadeIn();
                checkForOneTouch();
            } else {
                $('.auth-token').fadeIn();
            }
        });
    };

    $('#login-form').submit(function(e) {
        e.preventDefault();
        var formData = $(e.currentTarget).serialize();
        attemptOneTouchVerification(formData);
    });

    $('#verification-login-btn').click(function() {
        var checked_val = document.querySelector('input[name = "two_factor_option"]:checked').value;
        if(checked_val == "Push Notification") {
            $('#push-notification-loader').removeClass("hidden");
        }
    });

    $('#phone_verification_push_btn').click(function() {
          $('#verification-loader').removeClass("hidden");
    });
});