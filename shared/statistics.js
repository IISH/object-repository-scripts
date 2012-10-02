/**
 * /shared/statistics.js
 *
 * Usage: mongo [database] --quiet --eval "var pid='pid';"
 *
 */

function map() {

    // Set interval according to the ISO
    /* use a function for the exact format desired... */
    function ISODateString(d) {
        function pad(n) {
            return n < 10 ? '0' + n : n
        }

        return d.getUTCFullYear() + '-'
            + pad(d.getUTCMonth() + 1) + '-'
            + pad(d.getUTCDate()) + 'T'
            + pad(d.getUTCHours()) + ':'
            + pad(d.getUTCMinutes()) + ':'
            + pad(d.getUTCSeconds()) + 'Z'
    }

    // Code from http://jsfiddle.net/sRxTs/1/
    function firstDayOfWeek(week, year) {

        if (typeof year !== 'undefined') {
            year = (new Date()).getFullYear();
        }

        var date = firstWeekOfYear(year),
            weekTime = weeksToMilliseconds(week),
            targetTime = date.getTime() + weekTime;

        return date.setTime(targetTime);

    }

    function weeksToMilliseconds(weeks) {
        return 1000 * 60 * 60 * 24 * 7 * (weeks - 1);
    }

    function firstWeekOfYear(year) {
        var date = new Date();
        date = firstDayOfYear(date, year);
        date = firstWeekday(date);
        return date;
    }

    function firstDayOfYear(date, year) {
        date.setYear(year);
        date.setDate(1);
        date.setMonth(0);
        date.setHours(0);
        date.setMinutes(0);
        date.setSeconds(0);
        date.setMilliseconds(0);
        return date;
    }

    function firstWeekday(date) {

        var day = date.getDay(),
            day = (day === 0) ? 7 : day;

        if (day > 3) {

            var remaining = 8 - day,
                target = remaining + 1;

            date.setDate(target);
        }

        return date;
    }

    if (this.metadata.cache) {
        this.metadata.cache.forEach(function (document) {
            var d = ISODateString(document.uploadDate);
            var key = null;
            switch (unit) {  // unit is a scope variable
                case 'year':
                    key = d.substring(0, 4) + "-01-01";
                    break;
                default:
                case 'month':
                    key = d.substring(0, 7) + "-01";
                    break;
                case 'day':
                    key = d.substring(0, 10);
                    break;
                case 'week':
                    var onejan = new Date(document.uploadDate.getUTCFullYear(), 0, 1);
                    var week = Math.ceil((((document.uploadDate - onejan) / 86400000) + onejan.getDay() + 1) / 7);
                    var fwoy = firstDayOfWeek(week, document.uploadDate.getFullYear());
                    key = ISODateString(new Date(fwoy)).substring(0, 10);
                    break;
            }
            var value = {};
            value[ "files.count"] = 1;
            value[ "files.length"] = document.length;
            //value[ "files.label.'" + document.metadata.label + "'"] = 1;
            value[ "files.count." + document.metadata.bucket] = 1;
            value[ "files.length." + document.metadata.bucket] = document.length;
            value[ "access.count." + document.metadata.access] = 1;
            value[ "contentType.count." + document.contentType] = 1;
            emit(new ISODate(key), value);
        });
    }
}

function reduce(key, values) {

    var reducto = {};
    values.forEach(function (value) {
        for (var key in value) {
            reducto[key] = (reducto[key] === undefined) ? value[key] : reducto[key] + value[key];
        }
        ;
    });
    return reducto;
}

['year', 'month', 'week', 'day'].forEach(function (unit) {
    var collection = unit + ".statistics";
    print("Collection: " + collection);
    if (pid) {
        var query = {'metadata.pid':pid};
        db.master.files.mapReduce(map, reduce, { out:{reduce:collection}, scope:{unit:unit}, query:query });
    } else {
        db.master.files.mapReduce(map, reduce, { out:{replace:collection}, scope:{unit:unit} });
    }
})
