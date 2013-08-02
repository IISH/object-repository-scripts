/**
 * /shared/statistics.js
 *
 * Usage: mongo [database] --quiet --eval "var pid='pid';var ns='namespace'"
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

        var day = date.getDay();
        day = (day === 0) ? 7 : day;

        if (day > 3) {
            var remaining = 8 - day;
            date.setDate(remaining + 1);
        }

        return date;
    }

    if (this.uploadDate && this.metadata && this.metadata.access) {
        var d = ISODateString(this.uploadDate);
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
                var onejan = new ISODate(this.uploadDate.getUTCFullYear()+"-01-01") ;
                var week = Math.ceil((((this.uploadDate - onejan) / 86400000) + onejan.getDay() + 1) / 7);
                var fwoy = firstDayOfWeek(week, this.uploadDate.getFullYear());
                key = ISODateString(new Date(fwoy)).substring(0, 10);
                break;
        }
        var value = {};
        value[ "files.count"] = 1;
        value[ "uploadDate." + ns] = this.uploadDate;
        value[ "files.length"] = this.length;
        value[ "files.count." + ns] = 1;
        value[ "files.length." + ns] = this.length;
        value[ "access.count." + this.metadata.access] = 1;
        value[ "contentType.count." + this.contentType] = 1;
        emit(new ISODate(key), value);
    }
}

function reduce(key, values) {
    var reducto = {};
    var uploadDate = new Date(0);
    values.forEach(function (value) {
        for (var k in value) {
            if (value.hasOwnProperty(k)) {
                if (k == 'uploadDate.'+ns)
                    reducto[k] = uploadDate = ( value[k] > uploadDate ) ? value[k] : uploadDate;
                else
                    reducto[k] = (reducto[k] === undefined) ? value[k] : reducto[k] + value[k];
            }
        }
    });
    return reducto;
}

['year', 'month', 'day'].forEach(function (unit) {
    var collection = "statistics.storage." + unit;
    ['master', 'level1', 'level2', 'level3'].forEach(function (ns) {
        var bucket = ns + '.files';
        var uploadDate_key = 'uploadDate.' + ns ;
        var from = db.getCollection(collection).find().sort({_id:-1}).limit(1);
        if (from.length() == 0 || from[0].value[uploadDate_key] === undefined) {
            var value = {value:{}};
            value.value[uploadDate_key] = new Date(0) ;
            from = [value];
        }
        var query = {uploadDate: {$gte: from[0].value[uploadDate_key]}};
        print('Running mapreduce on collection ' + collection + ' on bucket ' + bucket + ' with query:') ;
        printjson(query) ;
        db.getCollection(bucket).mapReduce(map, reduce, { out: {reduce: collection}, scope: {unit: unit, ns:ns}, query:query});
    });
});
