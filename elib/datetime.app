module elib/datetime

  function latest(t1: DateTime, t2: DateTime): DateTime {
  	if(t1 == null) { return t2; }
  	if(t2 == null) { return t1; }
  	if(t1.after(t2)) { return t1; } else { return t2; }
  }
  
  function earliest(t1: DateTime, t2: DateTime): DateTime {
  	if(t1 == null) { return t2; }
  	if(t2 == null) { return t1; }
  	if(t1.before(t2)) { return t1; } else { return t2; }
  }

  function age(now: DateTime, time : DateTime) : String {
    var then : Long := time.getTime();
    var now : Long := now.getTime();
    var interval : Long := (now - then) / 60000L;
    if(interval < 2)  { return "one minute"; }
    if(interval < 60) { return interval + " minutes"; }
    if(interval < 120) { return  "one hour"; }
    interval := interval / 60L;
    if(interval < 24) { return interval + " hours"; }
    if(interval < 36) { return "1 day"; }
    if(interval < 48) { return "2 days"; }
    interval := interval / 24L;
    if(interval <= 30) { return interval + " days"; }
    interval := 1 + interval / 30L;
    if(interval <= 12) { return interval + " months"; }
    interval := interval / 12L;
    return interval + " years";
  }
  
  function age(time : DateTime) : String {
  	return age(now(), time);
  }
  
  function remaining(time: DateTime): String {
  	return age(time, now());
  }

  function seconds(x : Long) : Long {
    var factor : Long := 1000L;
    return factor * x;
  }

  function minutes(x : Long) : Long {
    var factor : Long := 60L;
    return seconds(x * factor);
  }

  function hours(x : Long) : Long {
    var factor : Long := 60L;
    return minutes(factor * x);
  }

  function days(x : Long) : Long {
    var factor : Long := 24L;
    return hours(x * factor);
  }

  function nextday(time : DateTime) : DateTime {
    var nextday : DateTime := now();
    //log(" time == null: " + (time == null));
    nextday.setTime(time.getTime() + days(1L));
    return nextday;
  }
  
  function add(x : DateTime, y : DateTime) : DateTime {
    var z : DateTime := now();
    z.setTime(x.getTime() + y.getTime());
    return z;
  }
  
  function add(x: DateTime, y: Long): DateTime {
    var z : DateTime := now();
    z.setTime(x.getTime() + y);
    return z;
  }

  function numberof(i : Int, one : String, many : String) : String {
    if(i <= 0) { return "no " + many; }
    if(i == 1) { return "one " + one; }
    return i + " " + many;
  }
  
  function days(start : Date, end : Date) : List<Date> {
    var days : List<Date>;
    if(start != null) {
      if(end == null) {
        days.add(start);
      } else {
        var next := start;
        while(!next.after(end)) {
          //log("next day: " + next);
          days.add(next);
          next := nextday(next);
        }
      }
    }
    return days;
  }
  
  native class java.sql.Timestamp as Timestamp : DateTime {
    constructor(Int)
  }
