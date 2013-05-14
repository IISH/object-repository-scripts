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
                var onejan = new Date(this.uploadDate.getUTCFullYear(), 0, 1);
                var week = Math.ceil((((this.uploadDate - onejan) / 86400000) + onejan.getDay() + 1) / 7);
                var fwoy = firstDayOfWeek(week, this.uploadDate.getFullYear());
                key = ISODateString(new Date(fwoy)).substring(0, 10);
                break;
        }
        var value = {};
        value[ "files.count"] = 1;
        value[ "files.length"] = this.length;
        value[ "files.count." + this.metadata.bucket] = 1;
        value[ "files.length." + this.metadata.bucket] = this.length;
        value[ "access.count." + this.metadata.access] = 1;
        value[ "contentType.count." + this.contentType] = 1;
        emit(new ISODate(key), value);
    }
}

function reduce(key, values) {
    var reducto = {};
    values.forEach(function (value) {
        for (var k in value) {
            if (value.hasOwnProperty(k))
                reducto[k] = (reducto[k] === undefined) ? value[k] : reducto[k] + value[k];
        }
    });
    return reducto;
}

['year', 'month', 'week', 'day'].forEach(function (unit) {
    var collection = unit + ".storage.statistics";
    print("Collection: " + collection);
    if (pid) {
        assert(ns, "When a PID value is defined, we must have a bucket value: var ns='ns'");
        var query = {'metadata.pid': pid};
        db.getCollection(ns + '.files').mapReduce(map, reduce, { out: {reduce: collection}, scope: {unit: unit}, query: query });
    } else {

        var last = db.getCollection(bucket).find().sort({uploadDate: -1}).limit(1);
        if (last == null) last = {uploadDate: new Date(0)};
        var query = {uploadDate: {$gte: last.uploadDate}};

        db.master.files.mapReduce(map, reduce, { out: {reduce: collection}, scope: {unit: unit}, query: query});
        db.level1.files.mapReduce(map, reduce, { out: {reduce: collection}, scope: {unit: unit}, query: query});
        db.level2.files.mapReduce(map, reduce, { out: {reduce: collection}, scope: {unit: unit}, query: query});
        db.level3.files.mapReduce(map, reduce, { out: {reduce: collection}, scope: {unit: unit}, query: query});
    }
});
