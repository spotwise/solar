import XCTest
@testable import Solar

final class SolarTests: XCTestCase {

    // Test helper functions to convert dates and degrees
    func testJulianDayNumber() throws {
        XCTAssertEqual(Solar().gregorian2jdn(year: 2021, month: 12, day: 26), 2459575)
    }
    func testHMS2Hours() throws {
        XCTAssertEqual(12.0, Solar().hms2hours(hours: 11, minutes: 59, seconds: 59), accuracy: 2/3600)
        XCTAssertEqual(15.0, Solar().hms2hours(hours: 15, minutes: 0, seconds: 0), accuracy: 2/3600)
        XCTAssertEqual(18.5, Solar().hms2hours(hours: 18, minutes: 30, seconds: 0), accuracy: 2/3600)
        XCTAssertEqual(20.75, Solar().hms2hours(hours: 20, minutes: 45, seconds: 1), accuracy: 2/3600)
    }
    func testHMS() throws {
        let hours = Solar().hms2hours(hours: 12, minutes: 23, seconds: 45)
        let (h, m, s) = Solar().hours2hms(hours: hours)
        XCTAssertEqual(hours, Solar().hms2hours(hours: h, minutes: m, seconds: Int(s)), accuracy: 2/3600)
    }
    
    // Test against NOAA sunset and sunrise times for Gothenburg for a few dates
    func testGOT2022() throws {
        
        // https://gml.noaa.gov/grad/solcalc/
        // GOTHENBURG = (latitude: 57.7063770, longitude: 11.9676197)
        
        let (sunrise0101, sunset0101) = Solar().getSunriseAndSunset(year: 2022, month: 1, day: 1, lat: Solar().GOTHENBURG.latitude, lng: Solar().GOTHENBURG.longitude, zenith: Solar().ZENITH_OFFICIAL)
        let (sunrise0311, sunset0311) = Solar().getSunriseAndSunset(year: 2022, month: 3, day: 11, lat: Solar().GOTHENBURG.latitude, lng: Solar().GOTHENBURG.longitude, zenith: Solar().ZENITH_OFFICIAL)
        let (sunrise0621, sunset0621) = Solar().getSunriseAndSunset(year: 2022, month: 6, day: 21, lat: Solar().GOTHENBURG.latitude, lng: Solar().GOTHENBURG.longitude, zenith: Solar().ZENITH_OFFICIAL)
        let (sunrise0901, sunset0901) = Solar().getSunriseAndSunset(year: 2022, month: 9, day: 1, lat: Solar().GOTHENBURG.latitude, lng: Solar().GOTHENBURG.longitude, zenith: Solar().ZENITH_OFFICIAL)

        XCTAssertEqual(sunrise0101, Solar().hms2hours(hours: 7, minutes: 55, seconds: 0), accuracy: 60/3600)
        XCTAssertEqual(sunrise0311, Solar().hms2hours(hours: 5, minutes: 39, seconds: 0), accuracy: 60/3600)
        XCTAssertEqual(sunrise0621, Solar().hms2hours(hours: 2, minutes: 11, seconds: 0), accuracy: 60/3600)
        XCTAssertEqual(sunrise0901, Solar().hms2hours(hours: 4, minutes: 12, seconds: 0), accuracy: 60/3600)

        XCTAssertEqual(sunset0101, Solar().hms2hours(hours: 14, minutes: 36, seconds: 0), accuracy: 60/3600)
        XCTAssertEqual(sunset0311, Solar().hms2hours(hours: 17, minutes: 6, seconds: 0), accuracy: 120/3600)
        XCTAssertEqual(sunset0621, Solar().hms2hours(hours: 20, minutes: 17, seconds: 0), accuracy: 60/3600)
        XCTAssertEqual(sunset0901, Solar().hms2hours(hours: 18, minutes: 11, seconds: 0), accuracy: 120/3600)
    }

    // Test the two algorithms against each other
    func testAlgorithms() throws {
        let (sunrise0101a, sunset0101a) = Solar().getSunriseAndSunset(year: 2022, month: 1, day: 1, lat: Solar().GOTHENBURG.latitude, lng: Solar().GOTHENBURG.longitude, zenith: Solar().ZENITH_OFFICIAL)
        let sunrise0101b = Solar().getSunriseOrSunset(year: 2021, month: 1, day: 1, lat: Solar().GOTHENBURG.latitude, lng: Solar().GOTHENBURG.longitude, zenith: Solar().ZENITH_OFFICIAL, sunrise: true)
        let sunset0101b = Solar().getSunriseOrSunset(year: 2021, month: 1, day: 1, lat: Solar().GOTHENBURG.latitude, lng: Solar().GOTHENBURG.longitude, zenith: Solar().ZENITH_OFFICIAL, sunrise: false)
        let (sunrise0621a, sunset0621a) = Solar().getSunriseAndSunset(year: 2022, month: 6, day: 21, lat: Solar().GOTHENBURG.latitude, lng: Solar().GOTHENBURG.longitude, zenith: Solar().ZENITH_OFFICIAL)
        let sunrise0621b = Solar().getSunriseOrSunset(year: 2021, month: 6, day: 21, lat: Solar().GOTHENBURG.latitude, lng: Solar().GOTHENBURG.longitude, zenith: Solar().ZENITH_OFFICIAL, sunrise: true)
        let sunset0621b = Solar().getSunriseOrSunset(year: 2021, month: 6, day: 21, lat: Solar().GOTHENBURG.latitude, lng: Solar().GOTHENBURG.longitude, zenith: Solar().ZENITH_OFFICIAL, sunrise: false)

        XCTAssertEqual(sunrise0101a, sunrise0101b, accuracy: 20/3600)
        XCTAssertEqual(sunset0101a, sunset0101b, accuracy: 60/3600)
        XCTAssertEqual(sunrise0621a, sunrise0621b, accuracy: 10/3600)
        XCTAssertEqual(sunset0621a, sunset0621b, accuracy: 10/3600)
    }
    
    // Test against known data from the "Solar Position Algorithm for Solar Radiation Applications"
    func testSPA() throws {
        // https://www.nrel.gov/docs/fy08osti/34302.pdf
        
        // First algorithm
        let (sunrise1, sunset1) = Solar().getSunriseAndSunset(year: 1994, month: 1, day: 2, lat: 35.0, lng: 0.0, zenith: Solar().ZENITH_OFFICIAL)
        let (sunrise2, sunset2) = Solar().getSunriseAndSunset(year: 1996, month: 7, day: 5, lat: -35.0, lng: 0.0, zenith: Solar().ZENITH_OFFICIAL)
        let (sunrise3, sunset3) = Solar().getSunriseAndSunset(year: 2004, month: 12, day: 4, lat: -35.0, lng: 0.0, zenith: Solar().ZENITH_OFFICIAL)

        XCTAssertEqual(sunrise1, Solar().hms2hours(hours: 7, minutes: 8, seconds: 13), accuracy: 10/3600)
        XCTAssertEqual(sunset1, Solar().hms2hours(hours: 16, minutes: 59, seconds: 56), accuracy: 20/3600)
        XCTAssertEqual(sunrise2, Solar().hms2hours(hours: 7, minutes: 8, seconds: 15), accuracy: 10/3600)
        XCTAssertEqual(sunset2, Solar().hms2hours(hours: 17, minutes: 1, seconds: 4), accuracy: 20/3600)
        XCTAssertEqual(sunrise3, Solar().hms2hours(hours: 4, minutes: 38, seconds: 57), accuracy: 20/3600)
        XCTAssertEqual(sunset3, Solar().hms2hours(hours: 19, minutes: 2, seconds: 2), accuracy: 10/3600)

        // Second algorithm (note: slightly lower accuracy)
        let sunrise4 = Solar().getSunriseOrSunset(year: 1994, month: 1, day: 2, lat: 35.0, lng: 0.0, zenith: Solar().ZENITH_OFFICIAL, sunrise: true)
        let sunset4 = Solar().getSunriseOrSunset(year: 1994, month: 1, day: 2, lat: 35.0, lng: 0.0, zenith: Solar().ZENITH_OFFICIAL, sunrise: false)
        let sunrise5 = Solar().getSunriseOrSunset(year: 1996, month: 7, day: 5, lat: -35.0, lng: 0.0, zenith: Solar().ZENITH_OFFICIAL, sunrise: true)
        let sunset5 = Solar().getSunriseOrSunset(year: 1996, month: 7, day: 5, lat: -35.0, lng: 0.0, zenith: Solar().ZENITH_OFFICIAL, sunrise: false)
        let sunrise6 = Solar().getSunriseOrSunset(year: 2004, month: 12, day: 4, lat: -35.0, lng: 0.0, zenith: Solar().ZENITH_OFFICIAL, sunrise: true)
        let sunset6 = Solar().getSunriseOrSunset(year: 2004, month: 12, day: 4, lat: -35.0, lng: 0.0, zenith: Solar().ZENITH_OFFICIAL, sunrise: false)

        XCTAssertEqual(sunrise4, Solar().hms2hours(hours: 7, minutes: 8, seconds: 13), accuracy: 10/3600)
        XCTAssertEqual(sunset4, Solar().hms2hours(hours: 16, minutes: 59, seconds: 56), accuracy: 20/3600)
        XCTAssertEqual(sunrise5, Solar().hms2hours(hours: 7, minutes: 8, seconds: 15), accuracy: 10/3600)
        XCTAssertEqual(sunset5, Solar().hms2hours(hours: 17, minutes: 1, seconds: 4), accuracy: 20/3600)
        XCTAssertEqual(sunrise6, Solar().hms2hours(hours: 4, minutes: 38, seconds: 57), accuracy: 20/3600)
        XCTAssertEqual(sunset6, Solar().hms2hours(hours: 19, minutes: 2, seconds: 2), accuracy: 20/3600)
    }
    
    // Test sample data from 1888
    func testAlgorithms1888() throws {
        // http://www.moonstick.com/sunset_calculation_example.htm
        let (_, sunseta) = Solar().getSunriseAndSunset(year: 1888, month: 1, day: 13, lat: 38.83333333, lng: -77, zenith: Solar().ZENITH_OFFICIAL)
        let sunsetb = Solar().getSunriseOrSunset(year: 1888, month: 1, day: 13, lat: 38.83333333, lng: -77, zenith: Solar().ZENITH_OFFICIAL, sunrise: false)

        XCTAssertEqual(sunseta, Solar().hms2hours(hours: 22, minutes: 7, seconds: 38), accuracy: 120/3600)
        XCTAssertEqual(sunsetb, Solar().hms2hours(hours: 22, minutes: 7, seconds: 38), accuracy: 60/3600)
    }
    
    // Test against known sunset and sunrise times in Gothenburg, Sweden
    func testGOT210601() throws {
        let (sunrise, sunset) = Solar().getSunriseAndSunset(year: 2021, month: 6, day: 1, lat: Solar().GOTHENBURG.latitude, lng: Solar().GOTHENBURG.longitude, zenith: Solar().ZENITH_OFFICIAL)

        XCTAssertEqual(sunrise, Solar().hms2hours(hours: 2, minutes: 21, seconds: 25), accuracy: 30/3600)
        XCTAssertEqual(sunset, Solar().hms2hours(hours: 19, minutes: 58, seconds: 4), accuracy: 60/3600)

    }
    func testSunriseGOT210601() throws {
        let sunrise = Solar().getSunriseOrSunset(year: 2021, month: 6, day: 1, lat: Solar().GOTHENBURG.latitude, lng: Solar().GOTHENBURG.longitude, zenith: Solar().ZENITH_OFFICIAL, sunrise: true)
        let sunset = Solar().getSunriseOrSunset(year: 2021, month: 6, day: 1, lat: Solar().GOTHENBURG.latitude, lng: Solar().GOTHENBURG.longitude, zenith: Solar().ZENITH_OFFICIAL, sunrise: false)

        XCTAssertEqual(sunrise, Solar().hms2hours(hours: 2, minutes: 21, seconds: 25), accuracy: 30/3600)
        XCTAssertEqual(sunset, Solar().hms2hours(hours: 19, minutes: 58, seconds: 4), accuracy: 30/3600)
    }
    func testSunriseGOT211226() throws {
        let sunrise: Double = Solar().getSunriseOrSunset(year: 2021, month: 12, day: 26, lat: Solar().GOTHENBURG.latitude, lng: Solar().GOTHENBURG.longitude, zenith: Solar().ZENITH_OFFICIAL, sunrise: true)
        XCTAssertEqual(sunrise, 7.932243703224639, accuracy: 30/3600)
    }
    func testGOT211226() throws {
        let (sunrise, sunset) = Solar().getSunriseAndSunset(year: 2021, month: 12, day: 26, lat: Solar().GOTHENBURG.latitude, lng: Solar().GOTHENBURG.longitude, zenith: Solar().ZENITH_OFFICIAL)

        XCTAssertEqual(sunrise, Solar().hms2hours(hours: 7, minutes: 55, seconds: 51), accuracy: 10/3600)
        XCTAssertEqual(sunset, Solar().hms2hours(hours: 14, minutes: 29, seconds: 11), accuracy: 10/3600)
    }
    func testGOT210101() throws {
        let (sunrise, sunset) = Solar().getSunriseAndSunset(year: 2021, month: 1, day: 1, lat: Solar().GOTHENBURG.latitude, lng: Solar().GOTHENBURG.longitude, zenith: Solar().ZENITH_OFFICIAL)

        XCTAssertEqual(sunrise, Solar().hms2hours(hours: 7, minutes: 55, seconds: 19), accuracy: 10/3600)
        XCTAssertEqual(sunset, Solar().hms2hours(hours: 14, minutes: 35, seconds: 47), accuracy: 10/3600)
    }
    func testGOT210301() throws {
        let (sunrise, sunset) = Solar().getSunriseAndSunset(year: 2021, month: 3, day: 1, lat: Solar().GOTHENBURG.latitude, lng: Solar().GOTHENBURG.longitude, zenith: Solar().ZENITH_OFFICIAL)

        XCTAssertEqual(sunrise, Solar().hms2hours(hours: 6, minutes: 6, seconds: 43), accuracy: 60/3600)
        XCTAssertEqual(sunset, Solar().hms2hours(hours: 16, minutes: 42, seconds: 15), accuracy: 60/3600)
    }

    
    // Verify that the sun never sets/rises on the poles during summer/winter
    func testSunriseNorthPole220101() throws {
        XCTAssertEqual(Solar().getSunriseOrSunset(year: 2021, month: 12, day: 26, lat: 90, lng: 0, zenith: Solar().ZENITH_OFFICIAL, sunrise: true), -1)
    }
    func testSunriseNorthPole220701() throws {
        XCTAssertEqual(Solar().getSunriseOrSunset(year: 2021, month: 12, day: 26, lat: 90, lng: 0, zenith: Solar().ZENITH_OFFICIAL, sunrise: false), -1)
    }
    func testSunriseSouthPole220101() throws {
        XCTAssertEqual(Solar().getSunriseOrSunset(year: 2021, month: 12, day: 26, lat: 90, lng: 0, zenith: Solar().ZENITH_OFFICIAL, sunrise: false), -1)
    }
    func testSunriseSouthPole220701() throws {
        XCTAssertEqual(Solar().getSunriseOrSunset(year: 2021, month: 12, day: 26, lat: 90, lng: 0, zenith: Solar().ZENITH_OFFICIAL, sunrise: true), -1)
    }

}
