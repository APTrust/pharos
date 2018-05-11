function timeline_graph(labels, data) {
    var ctx = document.getElementById("indiv_timeline_chart").getContext('2d');
    var repeat = Math.ceil(data.length/100);
    var colors, dark_colors;
    if (repeat == 1) {
        colors = palette('rainbow', data.length, 0, 0.5, 1).map(function(hex) {
            return '#' + hex;
        });
        dark_colors = palette('rainbow', data.length, 0, 1, 0.5).map(function(hex) {
            return '#' + hex;
        });
    } else {
        colors = [];
        dark_colors = [];
        for (var i = 0; i < repeat; i++) {
            var temp_colors = palette('rainbow', 100, 0, 0.5, 1).map(function(hex) {
                return '#' + hex;
            });
            colors.concat(temp_colors);
            var temp_dark_colors = palette('rainbow', 100, 0, 1, 0.5).map(function(hex) {
                return '#' + hex;
            });
            dark_colors.concat(temp_dark_colors);
        }
    }
    var myChart = new Chart(ctx, {
        type: 'horizontalBar',
        data: {
            labels: labels,
            datasets: [{
                label: 'Gigabytes Preserved',
                data: data,
                backgroundColor: colors,
                borderColor: dark_colors,
                borderWidth: 1
            }]
        },
        options: {
            scales: {
                yAxes: [{
                    ticks: {
                        beginAtZero:true
                    }
                }],
                xAxes: [{
                    scaleLabel: {
                        display: true,
                        labelString: "Amount of Data Preserved in Gigabytes"
                    }
                }]
            }
        }
    });
}

function mimetype_graph(stats, id, position) {
    var ctx = document.getElementById(id).getContext('2d');
    var labels_array = [];
    var data_array = [] ;
    Object.keys(stats).forEach(function (key) {
        var value = stats[key];
        labels_array.push(key);
        data_array.push(value);
    });
    var colors = get_colors(data_array.length);
    var myPieChart = new Chart(ctx,{
        type: 'doughnut',
        data: {
            labels: labels_array,
            datasets: [{
                data: data_array,
                label: 'Mimetype Usage',
                backgroundColor: colors,
                borderWidth: .5
            }]
        },
        options: {
            cutoutPercentage: 30,
            rotation: -0.5 * Math.PI,
            circumference: 2 * Math.PI,
            animation: {
                animateRotate: true
            },
            responsive: false,
            maintainAspectRatio: false,
            legend: {
                position: position,
                labels: {
                    fontSize: 10,
                    boxWidth: 25
                }
            }
        }
    });
}

function shuffleArray(color_array) {
    for (var i = color_array.length - 1; i > 0; i--) {
        var j = Math.floor(Math.random() * (i + 1));
        var temp_one = color_array[i];
        color_array[i] = color_array[j];
        color_array[j] = temp_one;
    }
    return color_array;
}

function get_colors(length) {
    var colors, colors_one, colors_two, colors_three, colors_four, colors_five = [];
    var color_length = 0;
    if (length <= 12) {
        colors = palette('tol', 12).map(function (hex) {
            return '#' + hex;
        });
    } else if (length >= 13 && length < 21) {
        colors = palette('mpn65', 21).map(function (hex) {
            return '#' + hex;
        });
    } else if (length >= 21 && length < 40) {
        color_length = Math.ceil(length/2);
        colors_one = palette('rainbow', color_length, 0, 1, 1).map(function (hex) {
            return '#' + hex;
        });
        colors_two = palette('tol-rainbow', color_length).map(function (hex) {
            return '#' + hex;
        });
        colors = colors_one.concat(colors_two);
    } else if (length >= 41 && length < 60) {
        color_length = Math.ceil(length/3);
        colors_one = palette('rainbow', color_length, 0, 1, 1).map(function (hex) {
            return '#' + hex;
        });
        colors_two = palette('tol-rainbow', color_length).map(function (hex) {
            return '#' + hex;
        });
        colors_three = palette('mpn65', color_length).map(function (hex) {
            return '#' + hex;
        });
        colors = colors_one.concat(colors_two.concat(colors_three));
    } else if (length >= 61 && length < 80) {
        color_length = Math.ceil(length/4);
        colors_one = palette('rainbow', color_length, 0, 1, 1).map(function (hex) {
            return '#' + hex;
        });
        colors_two = palette('tol-rainbow', color_length).map(function (hex) {
            return '#' + hex;
        });
        colors_three = palette('mpn65', color_length).map(function (hex) {
            return '#' + hex;
        });
        colors_four = palette('rainbow', color_length, 0, 0.6, 0.7).map(function (hex) {
            return '#' + hex;
        });
        colors = colors_one.concat(colors_two.concat(colors_three.concat(colors_four)));
    } else {
        color_length = Math.ceil((length - 46)/3);
        colors_one = palette('rainbow', color_length, 0, 1, 1).map(function (hex) {
            return '#' + hex;
        });
        colors_two = palette('tol-rainbow', 25).map(function (hex) {
            return '#' + hex;
        });
        colors_three = palette('mpn65', 21).map(function (hex) {
            return '#' + hex;
        });
        colors_four = palette('rainbow', color_length, 0, 1, 0.5).map(function (hex) {
            return '#' + hex;
        });
        colors_five = palette('rainbow', color_length, 0, 0.5, 1).map(function (hex) {
            return '#' + hex;
        });
        colors = colors_one.concat(colors_two.concat(colors_three.concat(colors_four.concat(colors_five))));
    }
    colors = shuffleArray(colors);
    return colors;
}