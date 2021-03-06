/**
 * /shared/siteusage.js
 *
 * Usage: mongo [database] siteusage.js
 *
 */

function map() {

    if (!this.downloadDate || this.c == '??') return;

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

            var remaining = 8 - day,
                target = remaining + 1;

            date.setDate(target);
        }

        return date;
    }

    var d = ISODateString(this.downloadDate);
    var key = null;
    switch (unit) {  // unit is a scope variable
        case 'all':
            key = "1970-01-01" ;
            break;
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
            var onejan = new Date(this.downloadDate.getUTCFullYear(), 0, 1);
            var week = Math.ceil((((this.downloadDate - onejan) / 86400000) + onejan.getDay() + 1) / 7);
            var fwoy = firstDayOfWeek(week, this.downloadDate.getFullYear());
            key = ISODateString(new Date(fwoy)).substring(0, 10);
            break;
    }
    var value = {};
    value["i"] = this._id;
    value[ this.bucket] = 1;
    var c = (this.c === undefined) ? 'IP' : this.c;
    value[c + "_" + this.bucket] = 1;
    value[ "total"] = 1;
    emit(new ISODate(key), value);
}

function reduce(k, values) {
    var reducto = {};
    var _id = null;
    values.forEach(function (value) {
        for (var key in value) {
            if (value.hasOwnProperty(key)) {
                if (key == "i") {
                    reducto['i'] = _id = ( _id == null || _id < value['i']) ? value['i'] : _id;
                } else
                    reducto[key] = (reducto[key] === undefined) ? value[key] : reducto[key] + value[key];
            }
        }
    });
    return reducto;
}

['all', 'year', 'month', 'day'].forEach(function (unit) {
    var collection =  "statistics.siteusage." + unit;
    var from = db.getCollection(collection).find().sort({_id: -1}).limit(1);
    var query = (from.length() == 0) ? {} : {_id: {$gte: from[0].value.i}};
    print('Running mapreduce on collection ' + collection + '  with query:');
    printjson(query);
    db.siteusage.mapReduce(map, reduce, { out: {reduce: collection}, scope: {unit: unit}, query: query });
});
