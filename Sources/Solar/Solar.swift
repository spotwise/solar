import Foundation

public struct Solar {

    // Zenith types
    public let ZENITH_OFFICIAL = 90.83333
    public let ZENITH_CIVIL = 96
    public let ZENITH_NAUTICAL = 102
    public let ZENITH_ASTRONOMICAL = 108

    // Göteborg: 57° 42' 22.9572" N  11° 58' 3.43092"E
    public let GOTHENBURG = (latitude: 57.7063770, longitude: 11.9676197)
    
    private func deg2rad(degrees: Double) -> Double {
        return degrees * Double.pi / 180
    }
    private func rad2deg(radians: Double) -> Double {
        return radians * 180 / Double.pi
    }
    
    public func gregorian2jdn(year:Int, month:Int, day:Int) -> Int {
        return  Int((1461 * (year + 4800 + Int((month - 14)/12)))/4) +
                Int((367 * (month - 2 - 12 * (Int((month - 14)/12))))/12) -
                Int((3 * ((year + 4900 + Int((month - 14)/12))/100))/4) +
                day - 32075
    }

    public func hours2hms(hours: Double) -> (hours: Int, minutes: Int, seconds: Double) {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60.0)
        let s = fmod((hours-Double(h)) * 3600, 60)
        return (h, m, s)
    }
    public func hms2hours(hours: Int, minutes: Int, seconds: Int) -> Double {
        return Double(hours) + ((Double(minutes) / 60.0) + (Double(seconds) / 3600.0))
    }
    
    public func degrees2dms(degrees: Double) -> (degrees: Int, minutes: Int, seconds: Double) {
        let d = Int(degrees)
        let m = Int((degrees - Double(d)) * 60.0)
        let s = fmod((degrees-Double(d))*3600, 60)
        return (d, m, s)
    }
        
    public func getSunriseAndSunset(year:Int, month:Int, day:Int, lat:Double, lng:Double, zenith:Double) -> (Double, Double) {

        // Adapted from https://en.wikipedia.org/wiki/Sunrise_equation

        // Current Julian day
        let jdn = Double(gregorian2jdn(year: year, month: month, day: day))
        let n = floor(jdn - 2451545.0 + 0.0008)

        // Mean solar time
        let js: Double = n - lng / 360.0

        // Solar mean anomaly
        let m: Double = fmod(357.5291 + 0.98560028 * js, 360.0)

        // Equation of the center
        let c: Double = 1.9148 * sin(deg2rad(degrees: m)) + 0.0200 * sin(deg2rad(degrees: 2*m)) + 0.0003 * sin(deg2rad(degrees: 3*m))

        // Ecliptic longitude
        let l: Double = fmod(m + c + 180.0 + 102.9372, 360.0)

        // Solar transit
        let jt: Double = 2451545.0 + js + 0.0053*sin(deg2rad(degrees: m)) - 0.0069*sin(deg2rad(degrees: 2*l))
        
        // Declination of the sun
        let sinD: Double = sin(deg2rad(degrees: l)) * sin(deg2rad(degrees: 23.44))
        let cosD: Double = cos(asin(sinD))
        
        // Hour angle
        let cosH: Double = (cos(deg2rad(degrees: zenith)) - (sinD * sin(deg2rad(degrees: lat)))) / (cosD * cos(deg2rad(degrees: lat)));

        let jRise: Double = cosH > 1  ? -1 : jt - rad2deg(radians: acos(cosH)) / 360.0
        let jSet: Double  = cosH < -1 ? -1 : jt + rad2deg(radians: acos(cosH)) / 360.0

        let rise = jRise.truncatingRemainder(dividingBy: 1)*24 - 12
        let set  = jSet.truncatingRemainder(dividingBy: 1)*24 + 12

        return (rise, set)
    }
    
    public func getSunriseOrSunset(year:Int, month:Int, day:Int, lat:Double, lng:Double, zenith:Double, sunrise:Bool) -> Double {
        
        // Adapted from https://math.stackexchange.com/a/2598266
        // Also see:    https://github.com/kelvins/sunrisesunset
        //              https://gist.github.com/adam-carter-fms/a44a14c0a8cdacbbc38276f6d553e024
        
        //let (r, s) = calculateSunriseSunset(year: year, month: month, day: day, lat: lat, lng: lng, zenith: zenith)
        //return sunrise ? r : s

        // Calculate the day of the year
        let n1: Int = 275 * month / 9
        let n2: Int = (month + 9) / 12
        let n3: Int = (1 + Int((year - 4 * Int(year / 4) + 2) / 3))
        let n: Int = n1 - (n2 * n3) + day - 30
        
        // Convert the longitude to hour value and calculate an approximate time
        let lngH: Double = lng / 15
        
        let t: Double = sunrise ? Double(n) + ((6.0-lngH) / 24.0) : Double(n) + ((18.0-lngH) / 24.0)

        // Calculate the sun's mean anomaly
        let m: Double = 0.9856*t - 3.289

        // Calculate the sun's true longitude
        let l: Double = fmod(m + (1.916 * sin(deg2rad(degrees: m))) + (0.020 * sin(deg2rad(degrees: 2*m))) + 282.634 + 360.0, 360.0)

        // Calculate the sun's right ascension
        var ra: Double = fmod(rad2deg(radians: atan(0.91764 * tan(deg2rad(degrees: l)))) + 360, 360)

        let lQ: Int = Int(l/90) * 90
        let raQ: Int = Int(ra/90) * 90
        ra += Double(lQ - raQ)
        ra /= 15.0

        // Calculate the sun's declination
        let sinD: Double = 0.39782 * sin(deg2rad(degrees: l))
        let cosD: Double = cos(asin(sinD))

        // Calculate the sun's local hour angle
        let cosH: Double = (cos(deg2rad(degrees: zenith)) - (sinD * sin(deg2rad(degrees: lat)))) / (cosD * cos(deg2rad(degrees: lat)));

        if(cosH > 1)
        {
            //print("The sun never rises on this location on this date");
            return -1;
        }
        if(cosH < -1)
        {
            //print("The sun never sets on this location on this date");
            return -1;
        }

        // Convert into hours
        var h: Double = sunrise ? 360 - rad2deg(radians: acos(cosH)) : rad2deg(radians: acos(cosH));

        h /= 15;

        // Calculate local mean time of rising/setting
        let mt: Double = h + ra - (0.06571*t) - 6.622;

        // Adjust back to UTC
        let ut: Double = fmod(mt - lngH + 24, 24);

        return ut
    }
}
