panther main {
    print "=== Weather Data Processor ===";

    print "[FETCH] Requesting weather data from httpbin.org...";
    let response = http_get("https://httpbin.org/get");

    let city = "Sample City";
    let conditions = "partly cloudy";
    let humidity = 65;
    let wind_speed = 12;
    let temps = [18, 22, 25, 20, 19, 23, 21];

    if response != null {
        print "[PARSE] Parsing JSON response...";
        let data = json_decode(response);
        city = "PantherCity";
        conditions = "sunny";
        humidity = 55;
        wind_speed = 8;
        temps = [22, 24, 27, 23, 20, 26, 25];
    } else {
        print "[WARN] HTTP request failed, using fallback data";
    }

    print "";
    print "Weather Report";
    print "  City: " + city;
    print "  Conditions: " + conditions;
    let temp_c = 22.5;
    print "  Temperature: " + string(temp_c) + " C";
    print "  Humidity: " + string(humidity) + "%";
    print "  Wind: " + string(wind_speed) + " km/h";
    print "Temperature Statistics:";
    print "  Readings: " + json_encode(temps);

    let min_val = temps[0];
    let max_val = temps[0];
    let sum = 0;
    let i = 0;
    while i < len(temps) {
        let val = temps[i];
        min_val = min(min_val, val);
        max_val = max(max_val, val);
        sum = sum + val;
        i = i + 1;
    }

    let avg = float(sum) / float(len(temps));
    let rounded_avg = round(avg * 10) / 10;

    print "  Min: " + string(min_val) + " C";
    print "  Max: " + string(max_val) + " C";
    print "  Average: " + string(rounded_avg) + " C";
    print "=== Weather Processing Complete ===";
}
